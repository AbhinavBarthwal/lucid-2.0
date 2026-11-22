//
//  ScreenBreakLiveActivityManager.swift
//  Lucid2.0
//
//  Starts/ends the Dynamic Island / Lock Screen Live Activity that shows an
//  estimated countdown to the next 20-20-20 break. Because DeviceActivity
//  only reports usage thresholds once they're reached (no live progress
//  signal), the countdown is an ETA based on the configured interval,
//  refreshed whenever the user (re)starts monitoring.
//

import Foundation
import ActivityKit

public final class ScreenBreakLiveActivityManager {
    public static let shared = ScreenBreakLiveActivityManager()

    private init() {}

    public func start(nextBreakAt: Date) {
        end()
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = ScreenBreakActivityAttributes()
        let state = ScreenBreakActivityAttributes.ContentState(nextBreakAt: nextBreakAt)

        do {
            _ = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nextBreakAt)
            )
        } catch {
            print("[ScreenBreakLiveActivityManager] Failed to start Live Activity: \(error)")
        }
    }

    public func end() {
        Task { @MainActor in
            for activity in Activity<ScreenBreakActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
