//
//  ScreenBreakViewModel.swift
//  Lucid2.0
//
//  Drives the 20-20-20 preventive-care card on the Protect tab: how long the
//  user can go before being nudged, which apps count toward that usage, and
//  whether the DeviceActivity-based reminder engine is armed.
//

import SwiftUI
import FamilyControls

@Observable
public final class ScreenBreakViewModel {
    /// Shared across the Protect tab and the Settings tab so both surfaces drive the same enable/
    /// disable state and Live Activity instead of maintaining two independent, divergent copies.
    public static let shared = ScreenBreakViewModel()

    public static let minIntervalMinutes: Double = 20
    public static let maxIntervalMinutes: Double = 120

    public var isEnabled: Bool
    public var intervalMinutes: Double
    public var selection: FamilyActivitySelection
    public var isAuthorized: Bool = false
    public var showAppPicker: Bool = false
    public var showLotus: Bool = false
    public var errorMessage: String?

    /// True while we've opened the app picker to let the user finish turning the toggle on, but
    /// haven't committed `isEnabled = true` yet — only once a real selection exists.
    private var pendingEnable: Bool = false

    private let service = ScreenTimeService.shared

    public init() {
        self.isEnabled = service.isScreenBreakEnabled
        self.intervalMinutes = Double(service.screenBreakIntervalMinutes)
        self.selection = service.screenBreakSelection() ?? FamilyActivitySelection()
        self.isAuthorized = service.isAuthorized
    }

    public var intervalFormatted: String {
        let minutes = Int(intervalMinutes.rounded())
        if minutes < 60 {
            return "\(minutes) min"
        }
        let hours = minutes / 60
        let remainder = minutes % 60
        return remainder == 0 ? "\(hours) hr" : "\(hours) hr \(remainder) min"
    }

    public var selectionSummary: String {
        let catCount = AppBlockingViewModel.rawCategoryCount(from: selection)
        let appCount = AppBlockingViewModel.rawAppCount(from: selection)
        if catCount == 0 && appCount == 0 {
            return "Choose apps"
        } else if catCount > 0 && appCount > 0 {
            return "\(catCount) Categor\(catCount == 1 ? "y" : "ies"), \(appCount) App\(appCount == 1 ? "" : "s")"
        } else if catCount > 0 {
            return "\(catCount) Categor\(catCount == 1 ? "y" : "ies")"
        } else {
            return "\(appCount) App\(appCount == 1 ? "" : "s")"
        }
    }

    public var hasSelection: Bool {
        AppBlockingViewModel.rawCategoryCount(from: selection) > 0 || AppBlockingViewModel.rawAppCount(from: selection) > 0
    }

    public func refreshAuthorization() {
        isAuthorized = service.isAuthorized
    }

    public func requestAuthorization() async {
        do {
            try await service.requestAuthorization()
            await MainActor.run { self.isAuthorized = self.service.isAuthorized }
        } catch {
            await MainActor.run {
                self.errorMessage = "Screen Time access was not granted: \(error.localizedDescription)"
            }
        }
    }

    /// Turns the 20-20-20 reminder on or off. Enabling without an app selection doesn't flip
    /// `isEnabled` yet — it opens the picker and waits for `selectionDidChange()` to confirm a real
    /// selection before committing, so the toggle can never show "on" while monitoring is actually
    /// disarmed.
    public func setEnabled(_ newValue: Bool) {
        if newValue {
            if hasSelection {
                isEnabled = true
                applySettings()
            } else {
                pendingEnable = true
                showAppPicker = true
            }
        } else {
            pendingEnable = false
            isEnabled = false
            applySettings()
        }
    }

    /// Call when `selection` changes (e.g. the app picker closes with a selection).
    public func selectionDidChange() {
        if pendingEnable, hasSelection {
            pendingEnable = false
            isEnabled = true
        }
        applySettings()
    }

    /// Call when the app picker sheet is dismissed, so a cancelled pick doesn't leave us waiting
    /// forever for a selection that's never coming.
    public func appPickerDismissed() {
        guard pendingEnable, !hasSelection else { return }
        pendingEnable = false
    }

    /// Re-arms monitoring from the current settings, but only if something actually changed from
    /// what's already persisted — a no-op settings-screen touch (e.g. opening and closing the app
    /// picker without changing anything, or releasing the slider on the same value) must not reset
    /// real progress toward the next break.
    public func applySettings() {
        guard isEnabled, hasSelection else {
            if service.isScreenBreakEnabled {
                service.stopScreenBreakMonitoring()
                ScreenBreakLiveActivityManager.shared.end()
            }
            return
        }

        let minutes = Int(intervalMinutes.rounded())
        let alreadyArmedWithSameSettings = service.isScreenBreakEnabled
            && service.screenBreakIntervalMinutes == minutes
            && service.screenBreakSelection() == selection
        guard !alreadyArmedWithSameSettings else { return }

        rearmMonitoring(minutes: minutes)
    }

    /// Call after the user completes an ad-hoc "Start Now" break — always restarts the countdown
    /// from zero, since they just took a break regardless of whether any setting changed.
    public func recordBreakTaken() {
        guard isEnabled, hasSelection else { return }
        rearmMonitoring(minutes: Int(intervalMinutes.rounded()))
    }

    private func rearmMonitoring(minutes: Int) {
        service.startScreenBreakMonitoring(selection: selection, intervalMinutes: minutes)
        let nextBreakAt = Date().addingTimeInterval(TimeInterval(minutes * 60))
        ScreenBreakLiveActivityManager.shared.start(nextBreakAt: nextBreakAt)
    }

    public func beginNow() {
        showLotus = true
    }
}
