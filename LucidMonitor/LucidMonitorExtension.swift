//
//  LucidMonitorExtension.swift
//  LucidMonitor
//
//  Created by Antigravity on 20/09/26.
//

import DeviceActivity
import ManagedSettings
import FamilyControls
import UserNotifications
import Foundation

// The DeviceActivityMonitor runs in the background extension process
// when schedule intervals begin or end.
class LucidMonitorExtension: DeviceActivityMonitor {
    private let store = ManagedSettingsStore()
    private let appGroupSuiteName = "group.com.lucid2.appgroup"

    private let screenBreakActivityName = DeviceActivityName("lucid.screenbreak")
    private let screenBreakEventName = DeviceActivityEvent.Name("lucid.screenbreak.usageThreshold")
    private let screenBreakEnabledKey = "screenbreak_enabled"
    private let screenBreakIntervalKey = "screenbreak_interval_minutes"
    private let screenBreakSelectionKey = "screenbreak_selection"

    private let screenBreakTips: [String] = [
        "Look at something 20 feet away for 20 seconds — your eyes have earned it.",
        "Time to unfocus. Rest your gaze on the horizon for 20 seconds.",
        "Blink a few times, then look far away for 20 seconds to relax your focus.",
        "Give your ciliary muscles a break — glance at something distant for 20 seconds.",
        "Screen break time. Look 20 feet away for 20 seconds before continuing."
    ]

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        guard activity.rawValue.hasPrefix("lucid.block.") else { return }

        guard let defaults = UserDefaults(suiteName: appGroupSuiteName) else {
            return
        }

        // Activity name is formatted as "lucid.block.<UUID>"
        let blockIdString = activity.rawValue.replacingOccurrences(of: "lucid.block.", with: "")

        // Attempt to load specific selection for this block
        if let specificData = defaults.data(forKey: "selection_\(blockIdString)"),
           let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: specificData) {
            applyShields(selection: selection)
            return
        }

        // Fallback to active general selection
        if let generalData = defaults.data(forKey: "active_selection"),
           let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: generalData) {
            applyShields(selection: selection)
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        guard activity.rawValue.hasPrefix("lucid.block.") else { return }
        clearShields()
    }

    override func eventDidReachThreshold(for activity: DeviceActivityName, event: DeviceActivityEvent.Name) {
        super.eventDidReachThreshold(for: activity, event: event)

        guard activity.rawValue == screenBreakActivityName.rawValue,
              event.rawValue == screenBreakEventName.rawValue else { return }

        postScreenBreakNotification()
        rearmScreenBreakMonitoring()
    }

    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
    }

    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
    }

    // MARK: - Private Helpers

    private func applyShields(selection: FamilyActivitySelection) {
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
    }

    private func clearShields() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }

    // MARK: - 20-20-20 Screen Break

    private func postScreenBreakNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Time for a 20-20-20 break"
        content.body = screenBreakTips.randomElement() ?? screenBreakTips[0]
        content.sound = .default
        content.userInfo = ["route": "screenbreak"]

        let request = UNNotificationRequest(
            identifier: "lucid.screenbreak.\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    /// DeviceActivity usage thresholds fire once per schedule occurrence, so we stop and
    /// re-start monitoring immediately — this resets the cumulative usage counter and lets
    /// the same threshold fire again later in the day, producing a repeating nudge.
    private func rearmScreenBreakMonitoring() {
        guard let defaults = UserDefaults(suiteName: appGroupSuiteName),
              defaults.bool(forKey: screenBreakEnabledKey),
              let data = defaults.data(forKey: screenBreakSelectionKey),
              let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
        else { return }

        let storedMinutes = defaults.integer(forKey: screenBreakIntervalKey)
        let intervalMinutes = storedMinutes > 0 ? storedMinutes : 40

        let center = DeviceActivityCenter()
        center.stopMonitoring([screenBreakActivityName])

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

        try? center.startMonitoring(
            screenBreakActivityName,
            during: schedule,
            events: [screenBreakEventName: event]
        )
    }
}
