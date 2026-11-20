//
//  ScreenTimeService.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import Foundation
import Combine
import FamilyControls
import DeviceActivity
import ManagedSettings

public final class ScreenTimeService: @unchecked Sendable {
    public static let shared = ScreenTimeService()

    private let center = DeviceActivityCenter()
    private let store = ManagedSettingsStore()
    private let appGroupSuiteName = "group.com.lucid2.appgroup"

    private init() {}

    // MARK: - Authorization

    public var isAuthorized: Bool {
        #if targetEnvironment(simulator)
        return UserDefaults.standard.bool(forKey: "lucid_screen_time_authorized_simulator")
        #else
        return AuthorizationCenter.shared.authorizationStatus == .approved
        #endif
    }

    @MainActor
    public func requestAuthorization() async throws {
        #if targetEnvironment(simulator)
        print("[ScreenTimeService] Running on Simulator. FamilyControls authorization is simulated.")
        UserDefaults.standard.set(true, forKey: "lucid_screen_time_authorized_simulator")
        #else
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        #endif
    }

    public func revokeAuthorizationSimulationForTesting() {
        #if targetEnvironment(simulator)
        UserDefaults.standard.removeObject(forKey: "lucid_screen_time_authorized_simulator")
        #endif
    }

    // MARK: - Schedule Monitoring (App Blocking)

    public func scheduleBlock(_ block: ScheduledBlock, selection: FamilyActivitySelection) {
        let activityName = DeviceActivityName("lucid.block.\(block.id.uuidString)")

        let startComponents = DateComponents(hour: block.fromHour, minute: block.fromMinute)
        let endComponents = DateComponents(hour: block.toHour, minute: block.toMinute)

        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: true
        )

        do {
            try center.startMonitoring(activityName, during: schedule)
            print("[ScreenTimeService] Successfully scheduled activity: \(activityName.rawValue)")
        } catch {
            print("[ScreenTimeService] Failed to schedule activity \(activityName.rawValue): \(error)")
        }

        // If block is active right now and matches today's weekday, apply shields immediately
        if isBlockActiveNow(block) {
            applyShield(for: selection)
        }
    }

    public func stopMonitoringBlock(id: UUID) {
        let activityName = DeviceActivityName("lucid.block.\(id.uuidString)")
        center.stopMonitoring([activityName])
        print("[ScreenTimeService] Stopped monitoring: \(activityName.rawValue)")
    }

    public func stopAllMonitoring() {
        center.stopMonitoring()
        clearShield()
    }

    // MARK: - Direct Shield Control

    public func applyShield(for selection: FamilyActivitySelection) {
        let appTokens = selection.applicationTokens.union(Set(selection.applications.compactMap { $0.token }))
        let catTokens = selection.categoryTokens.union(Set(selection.categories.compactMap { $0.token }))

        store.shield.applications = appTokens.isEmpty ? nil : appTokens
        store.shield.applicationCategories = catTokens.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(catTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        print("[ScreenTimeService] Applied shields for \(appTokens.count) apps and \(catTokens.count) categories")
    }

    public func clearShield() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        print("[ScreenTimeService] Cleared all shields")
    }

    // MARK: - Time Calculations

    public func isBlockActiveNow(_ block: ScheduledBlock) -> Bool {
        guard block.isEnabled else { return false }

        let now = Date()
        let calendar = Calendar.current
        let currentWeekdayInt = calendar.component(.weekday, from: now) // 1=Sun, 2=Mon...
        guard let currentWeekday = Weekday(rawValue: currentWeekdayInt) else { return false }

        guard block.days.contains(currentWeekday) else { return false }

        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTotalMinutes = currentHour * 60 + currentMinute

        let fromTotalMinutes = block.fromHour * 60 + block.fromMinute
        let toTotalMinutes = block.toHour * 60 + block.toMinute

        if fromTotalMinutes <= toTotalMinutes {
            // Normal range within same day (e.g. 18:00 to 18:45)
            return currentTotalMinutes >= fromTotalMinutes && currentTotalMinutes < toTotalMinutes
        } else {
            // Spans midnight (e.g. 23:00 to 02:00)
            return currentTotalMinutes >= fromTotalMinutes || currentTotalMinutes < toTotalMinutes
        }
    }

    // MARK: - 20-20-20 Screen Break Monitoring (Usage Threshold)

    public static let screenBreakActivityName = DeviceActivityName("lucid.screenbreak")
    public static let screenBreakEventName = DeviceActivityEvent.Name("lucid.screenbreak.usageThreshold")

    private static let screenBreakEnabledKey = "screenbreak_enabled"
    private static let screenBreakIntervalKey = "screenbreak_interval_minutes"
    private static let screenBreakSelectionKey = "screenbreak_selection"

    private var appGroupDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupSuiteName)
    }

    public var isScreenBreakEnabled: Bool {
        appGroupDefaults?.bool(forKey: Self.screenBreakEnabledKey) ?? false
    }

    public var screenBreakIntervalMinutes: Int {
        let value = appGroupDefaults?.integer(forKey: Self.screenBreakIntervalKey) ?? 0
        return value > 0 ? value : 40
    }

    public func screenBreakSelection() -> FamilyActivitySelection? {
        guard let data = appGroupDefaults?.data(forKey: Self.screenBreakSelectionKey) else { return nil }
        return try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
    }

    public var hasScreenBreakSelection: Bool {
        guard let selection = screenBreakSelection() else { return false }
        return !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty
            || !selection.applications.isEmpty || !selection.categories.isEmpty
    }

    /// Re-enables monitoring using whatever selection/interval was last configured in the Protect tab.
    public func enableScreenBreakMonitoringUsingStoredSelection() {
        guard let selection = screenBreakSelection() else { return }
        startScreenBreakMonitoring(selection: selection, intervalMinutes: screenBreakIntervalMinutes)
    }

    /// Starts (or re-starts) usage-threshold monitoring for the 20-20-20 reminder.
    /// Because DeviceActivity thresholds fire once per schedule occurrence, `LucidMonitorExtension`
    /// re-arms this same monitor every time the threshold is reached, so the nudge effectively
    /// repeats every `intervalMinutes` of cumulative usage until midnight resets the occurrence.
    public func startScreenBreakMonitoring(selection: FamilyActivitySelection, intervalMinutes: Int) {
        guard let defaults = appGroupDefaults else { return }

        if let data = try? PropertyListEncoder().encode(selection) {
            defaults.set(data, forKey: Self.screenBreakSelectionKey)
        }
        defaults.set(intervalMinutes, forKey: Self.screenBreakIntervalKey)
        defaults.set(true, forKey: Self.screenBreakEnabledKey)

        armScreenBreakMonitoring(selection: selection, intervalMinutes: intervalMinutes)
    }

    public func stopScreenBreakMonitoring() {
        appGroupDefaults?.set(false, forKey: Self.screenBreakEnabledKey)
        center.stopMonitoring([Self.screenBreakActivityName])
    }

    private func armScreenBreakMonitoring(selection: FamilyActivitySelection, intervalMinutes: Int) {
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            webDomains: selection.webDomainTokens,
            threshold: DateComponents(minute: intervalMinutes)
        )
        do {
            try center.startMonitoring(
                Self.screenBreakActivityName,
                during: schedule,
                events: [Self.screenBreakEventName: event]
            )
        } catch {
            print("[ScreenTimeService] Failed to arm screen break monitoring: \(error)")
        }
    }
}
