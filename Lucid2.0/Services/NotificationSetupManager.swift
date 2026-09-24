//
//  NotificationSetupManager.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import Foundation
import UserNotifications
import UIKit

public final class NotificationSetupManager: @unchecked Sendable {
    public static let shared = NotificationSetupManager()

    private let dismissedDateKey = "lucid_notification_card_dismissed_at"
    private let cooldownDays: Int = 15

    private init() {}

    /// Checks whether notifications are currently authorized in system settings.
    public func areNotificationsEnabled() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined, .denied:
            return false
        @unknown default:
            return false
        }
    }

    /// Checks if the notification setup card was dismissed within the 15-day cooldown period.
    public func isDismissedWithinCooldown() -> Bool {
        guard let dismissedDate = UserDefaults.standard.object(forKey: dismissedDateKey) as? Date else {
            return false
        }
        guard let expirationDate = Calendar.current.date(byAdding: .day, value: cooldownDays, to: dismissedDate) else {
            return false
        }
        return Date() < expirationDate
    }

    /// Records the current timestamp as the dismissal date.
    public func markCardDismissed() {
        UserDefaults.standard.set(Date(), forKey: dismissedDateKey)
    }

    /// Determines whether the notification setup card should be displayed.
    /// - Returns: `false` if notifications are already enabled OR if dismissed within 15 days.
    public func shouldShowCard() async -> Bool {
        // 1. If dismissed within the last 15 days, do not show.
        if isDismissedWithinCooldown() {
            return false
        }

        // 2. If notifications are enabled, do not show.
        let enabled = await areNotificationsEnabled()
        if enabled {
            return false
        }

        return true
    }

    /// Requests notification permissions. If previously denied, directs to iOS Settings.
    @MainActor
    public func requestAuthorization() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        if settings.authorizationStatus == .denied {
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString),
               UIApplication.shared.canOpenURL(settingsUrl) {
                await UIApplication.shared.open(settingsUrl)
            }
            return false
        }

        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("[NotificationSetupManager] Error requesting authorization: \(error)")
            return false
        }
    }

    #if DEBUG
    /// For debugging/testing: reset the dismissal cooldown
    public func resetDismissal() {
        UserDefaults.standard.removeObject(forKey: dismissedDateKey)
    }
    #endif
}
