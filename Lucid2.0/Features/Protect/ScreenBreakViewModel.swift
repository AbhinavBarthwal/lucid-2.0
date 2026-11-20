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
    public static let minIntervalMinutes: Double = 20
    public static let maxIntervalMinutes: Double = 120

    public var isEnabled: Bool
    public var intervalMinutes: Double
    public var selection: FamilyActivitySelection
    public var isAuthorized: Bool = false
    public var showAppPicker: Bool = false
    public var showLotus: Bool = false
    public var errorMessage: String?

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

    /// Call after toggling `isEnabled`, changing `intervalMinutes`, or changing `selection`.
    public func applySettings() {
        if isEnabled, hasSelection {
            let minutes = Int(intervalMinutes.rounded())
            service.startScreenBreakMonitoring(selection: selection, intervalMinutes: minutes)
            let nextBreakAt = Date().addingTimeInterval(TimeInterval(minutes * 60))
            ScreenBreakLiveActivityManager.shared.start(nextBreakAt: nextBreakAt)
        } else {
            service.stopScreenBreakMonitoring()
            ScreenBreakLiveActivityManager.shared.end()
        }
    }

    public func beginNow() {
        showLotus = true
    }
}
