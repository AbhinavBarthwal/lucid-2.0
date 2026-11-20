//
//  NotificationEngine.swift
//  Lucid2.0
//
//  Central local-notification scheduler: daily exercise reminders, vision
//  test due-dates, a streak-saver evening nudge, weekly insights, and the
//  eye-care tips engine. Also the UNUserNotificationCenterDelegate that
//  routes a tapped notification to the right tab via NotificationRouter.
//

import Foundation
import UserNotifications

public final class NotificationEngine: NSObject, UNUserNotificationCenterDelegate {
    public static let shared = NotificationEngine()

    private enum ID {
        static let dailyExercise = "lucid.notification.dailyExercise"
        static let testReminder = "lucid.notification.testReminder"
        static let streakSaver = "lucid.notification.streakSaver"
        static let weeklyInsight = "lucid.notification.weeklyInsight"
    }

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - Public entry point

    /// Call on launch, on foreground, and after any setting or completion change.
    public func refreshAllSchedules() {
        Task {
            guard await NotificationSetupManager.shared.areNotificationsEnabled() else { return }
            await MainActor.run {
                self.scheduleDailyExerciseReminder()
                self.scheduleTestReminder()
                self.scheduleStreakSaverReminder()
                self.scheduleWeeklyInsight()
            }
            EyeCareTipsEngine.shared.refillIfNeeded()
        }
    }

    // MARK: - Daily Exercise Reminder

    private func scheduleDailyExerciseReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [ID.dailyExercise])

        guard defaultedBool("lucid_setting_daily_reminder", default: true) else { return }

        let hour = UserDefaults.standard.object(forKey: "lucid_setting_reminder_hour") as? Int ?? 10
        let minute = UserDefaults.standard.object(forKey: "lucid_setting_reminder_minute") as? Int ?? 0

        let content = UNMutableNotificationContent()
        content.title = "Time for today's eye exercises"
        content.body = "Your daily vision stack is ready — just a couple minutes to protect your eyes."
        content.sound = .default
        content.userInfo = ["route": "exercise"]

        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        center.add(UNNotificationRequest(identifier: ID.dailyExercise, content: content, trigger: trigger))
    }

    // MARK: - Vision Test Reminder

    private func scheduleTestReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [ID.testReminder])

        let manager = TestScheduleManager.shared
        manager.checkDueStatus()

        let content = UNMutableNotificationContent()
        content.title = "Vision check-in time"
        content.body = "Your biweekly vision tests (Visual Acuity & Dry Eye Check) are ready — just a few minutes."
        content.sound = .default
        content.userInfo = ["route": "visionTest"]

        let trigger: UNNotificationTrigger
        if manager.isTestDue {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60 * 60, repeats: false)
        } else if let lastCompleted = manager.lastCompletedDate,
                  let nextDue = Calendar.current.date(byAdding: .day, value: 14, to: lastCompleted) {
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: nextDue)
            comps.hour = 10
            trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        } else {
            return
        }

        center.add(UNNotificationRequest(identifier: ID.testReminder, content: content, trigger: trigger))
    }

    // MARK: - Streak Saver

    private func scheduleStreakSaverReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [ID.streakSaver])

        guard defaultedBool("lucid_setting_streak_saver", default: true) else { return }
        guard !StreakManager.shared.isCompletedToday else { return }

        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour = 20
        comps.minute = 0
        guard let fireDate = Calendar.current.date(from: comps), fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Your streak is at risk"
        content.body = StreakManager.shared.streakStatusDescription
        content.sound = .default
        content.userInfo = ["route": "exercise"]

        let triggerComps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComps, repeats: false)
        center.add(UNNotificationRequest(identifier: ID.streakSaver, content: content, trigger: trigger))
    }

    // MARK: - Weekly Insights

    private func scheduleWeeklyInsight() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [ID.weeklyInsight])

        guard defaultedBool("lucid_setting_weekly_reports", default: true) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Your Weekly Vision Insights are ready"
        content.body = "See your streak, exercise consistency, and screen time saved this week."
        content.sound = .default
        content.userInfo = ["route": "none"]

        var comps = DateComponents()
        comps.weekday = 1 // Sunday
        comps.hour = 18
        comps.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        center.add(UNNotificationRequest(identifier: ID.weeklyInsight, content: content, trigger: trigger))
    }

    // MARK: - Helpers

    private func defaultedBool(_ key: String, default defaultValue: Bool) -> Bool {
        guard UserDefaults.standard.object(forKey: key) != nil else { return defaultValue }
        return UserDefaults.standard.bool(forKey: key)
    }

    // MARK: - UNUserNotificationCenterDelegate

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let route = response.notification.request.content.userInfo["route"] as? String else { return }
        await MainActor.run {
            switch route {
            case "exercise":
                NotificationRouter.shared.pendingRoute = .exercise
            case "visionTest":
                NotificationRouter.shared.pendingRoute = .visionTest
            case "screenbreak":
                NotificationRouter.shared.pendingRoute = .screenBreak
            default:
                break
            }
        }
    }
}
