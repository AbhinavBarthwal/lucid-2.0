//
//  EyeCareTipsEngine.swift
//  Lucid2.0
//
//  Keeps a rolling window of daily eye-care tip notifications scheduled at a
//  random time each day (within waking hours), topping the window back up
//  whenever it runs low so tips keep arriving without ever stacking up.
//

import Foundation
import UserNotifications

public final class EyeCareTipsEngine {
    public static let shared = EyeCareTipsEngine()

    private init() {}

    private let tips: [String] = [
        "Follow the 20-20-20 rule: every 20 minutes, look at something 20 feet away for 20 seconds.",
        "Blink fully and often — screens can cut your natural blink rate by more than half.",
        "Position your screen slightly below eye level so you don't have to open your eyes as wide.",
        "Keep screens at least an arm's length away to ease focusing strain.",
        "Try warmer, dimmer screen colors in the evening to ease digital eye strain before bed.",
        "Match your screen brightness to the light in the room around you.",
        "Dry eyes? Try palming: cover closed eyes gently with your palms for 30 seconds.",
        "Get a full eye exam at least once a year, even if your vision feels fine.",
        "Staying hydrated can help reduce dry-eye symptoms from screen use.",
        "Increase text size instead of leaning closer to the screen.",
        "A 5-minute walk outside resets your focus with natural light and distance vision.",
        "We blink less when reading or scrolling — make a conscious effort to blink more."
    ]

    private let identifierPrefix = "lucid.tip."
    private let windowStartHour = 9
    private let windowEndHour = 21
    private let horizonDays = 5
    private let minimumScheduledCount = 2

    /// Tops up the scheduled tip notifications if fewer than `minimumScheduledCount` remain pending.
    public func refillIfNeeded() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { [weak self] requests in
            guard let self else { return }
            let scheduledCount = requests.filter { $0.identifier.hasPrefix(self.identifierPrefix) }.count
            guard scheduledCount < self.minimumScheduledCount else { return }
            self.scheduleUpcomingTips(center: center)
        }
    }

    private func scheduleUpcomingTips(center: UNUserNotificationCenter) {
        let calendar = Calendar.current
        var recentlyUsed: [String] = []

        for dayOffset in 0..<horizonDays {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else { continue }

            let randomHour = Int.random(in: windowStartHour..<windowEndHour)
            let randomMinute = Int.random(in: 0..<60)
            guard var fireDate = calendar.date(bySettingHour: randomHour, minute: randomMinute, second: 0, of: day) else { continue }
            if fireDate <= Date() {
                guard let pushedToTomorrow = calendar.date(byAdding: .day, value: 1, to: fireDate) else { continue }
                fireDate = pushedToTomorrow
            }

            var pool = tips.filter { !recentlyUsed.contains($0) }
            if pool.isEmpty { pool = tips }
            guard let tip = pool.randomElement() else { continue }
            recentlyUsed.append(tip)
            if recentlyUsed.count > 3 { recentlyUsed.removeFirst() }

            let content = UNMutableNotificationContent()
            content.title = "Eye Care Tip"
            content.body = tip
            content.sound = .default
            content.userInfo = ["route": "none"]

            let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(identifier: "\(identifierPrefix)\(dayOffset)", content: content, trigger: trigger)
            center.add(request)
        }
    }
}
