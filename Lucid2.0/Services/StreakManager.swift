//
//  StreakManager.swift
//  Lucid2.0
//
//  Created by Antigravity on 24/09/26.
//

import Foundation
import SwiftUI

public struct WeeklyDayStatus: Identifiable, Hashable, Sendable {
    public var id: String { dateString }
    public let date: Date
    public let dateString: String
    public let dayLetter: String
    public let isToday: Bool
    public let isCompleted: Bool
    public let isPast: Bool

    public init(
        date: Date,
        dateString: String,
        dayLetter: String,
        isToday: Bool,
        isCompleted: Bool,
        isPast: Bool
    ) {
        self.date = date
        self.dateString = dateString
        self.dayLetter = dayLetter
        self.isToday = isToday
        self.isCompleted = isCompleted
        self.isPast = isPast
    }
}

@Observable
public final class StreakManager {
    public static let shared = StreakManager()

    public private(set) var currentStreak: Int = 0
    public private(set) var bestStreak: Int = 0
    public private(set) var totalExercisesCompleted: Int = 0
    public private(set) var todayExercisesCompleted: Int = 0
    public private(set) var lastCompletedDate: Date?
    public private(set) var completedDates: Set<String> = []

    public var dailyTarget: Int = 1 // Minimum exercises to maintain streak

    // Storage keys
    private let streakKey = "lucid_day_streak"
    private let bestStreakKey = "lucid_best_streak"
    private let totalExercisesKey = "lucid_exercises_completed"
    private let lastExerciseDateKey = "lucid_last_exercise_date"
    private let completedDatesKey = "lucid_completed_dates"
    private let streakSaverKey = "lucid_setting_streak_saver"

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    public init() {
        loadStreakData()
        refreshStreakState()
    }

    public var isCompletedToday: Bool {
        let todayStr = dateFormatter.string(from: Date())
        return completedDates.contains(todayStr)
    }

    public var isStreakSaverEnabled: Bool {
        if UserDefaults.standard.object(forKey: streakSaverKey) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: streakSaverKey)
    }

    public var streakStatusTitle: String {
        if currentStreak == 0 {
            return "Start Your Streak!"
        } else if isCompletedToday {
            return "\(currentStreak) Day Streak Active!"
        } else {
            return "\(currentStreak) Day Streak at Risk"
        }
    }

    public var streakStatusDescription: String {
        if currentStreak == 0 {
            return "Complete 1 eye exercise today to ignite your vision streak."
        } else if isCompletedToday {
            return "Flame safe! You've protected your eyes with daily exercises today."
        } else {
            return "Complete 1 exercise before midnight to extend your streak to \(currentStreak + 1) days!"
        }
    }

    public var shareText: String {
        let streakText = currentStreak == 1 ? "1-day" : "\(currentStreak)-day"
        return """
        🔥 I'm on a \(streakText) eye care streak on Lucid!
        👀 Taking care of my screen vision with daily focus and eye training.
        Protect your vision too: https://lucid.app
        """
    }

    // MARK: - Loading & Persistence

    private func loadStreakData() {
        let defaults = UserDefaults.standard
        self.currentStreak = defaults.integer(forKey: streakKey)
        self.bestStreak = defaults.integer(forKey: bestStreakKey)
        self.totalExercisesCompleted = defaults.integer(forKey: totalExercisesKey)

        if let savedDate = defaults.object(forKey: lastExerciseDateKey) as? Date {
            self.lastCompletedDate = savedDate
        }

        if let dates = defaults.stringArray(forKey: completedDatesKey) {
            self.completedDates = Set(dates)
        }
    }

    private func saveStreakData() {
        let defaults = UserDefaults.standard
        defaults.set(currentStreak, forKey: streakKey)
        defaults.set(bestStreak, forKey: bestStreakKey)
        defaults.set(totalExercisesCompleted, forKey: totalExercisesKey)
        if let lastCompletedDate {
            defaults.set(lastCompletedDate, forKey: lastExerciseDateKey)
        }
        defaults.set(Array(completedDates), forKey: completedDatesKey)
    }

    // MARK: - Streak Evaluation

    public func refreshStreakState() {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let todayStr = dateFormatter.string(from: now)

        if completedDates.contains(todayStr) {
            todayExercisesCompleted = max(1, todayExercisesCompleted)
        } else {
            todayExercisesCompleted = 0
        }

        guard let lastDate = lastCompletedDate else {
            if currentStreak > 0 && !completedDates.contains(todayStr) {
                currentStreak = 0
                saveStreakData()
            }
            return
        }

        let lastDay = calendar.startOfDay(for: lastDate)
        let daysBetween = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

        if daysBetween == 0 {
            // Already completed today, streak remains intact
        } else if daysBetween == 1 {
            // Completed yesterday; pending completion today
        } else if daysBetween == 2 && isStreakSaverEnabled {
            // Grace period: missed yesterday but saved by streak saver
        } else {
            // Lapsed more than allowed gap
            currentStreak = 0
            saveStreakData()
        }
    }

    // MARK: - Exercise Completion

    public func recordExerciseCompleted(exerciseId: String? = nil, date: Date = Date()) {
        let calendar = Calendar.current
        let now = date
        let today = calendar.startOfDay(for: now)
        let todayStr = dateFormatter.string(from: now)

        totalExercisesCompleted += 1
        todayExercisesCompleted += 1

        let wasAlreadyCompletedToday = completedDates.contains(todayStr)
        completedDates.insert(todayStr)

        if !wasAlreadyCompletedToday {
            if let lastDate = lastCompletedDate {
                let lastDay = calendar.startOfDay(for: lastDate)
                let daysBetween = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

                if daysBetween == 1 {
                    // Consecutive day streak increment
                    currentStreak += 1
                } else if daysBetween == 2 && isStreakSaverEnabled {
                    // Saved by streak saver
                    currentStreak += 1
                } else if daysBetween == 0 {
                    currentStreak = max(1, currentStreak)
                } else {
                    // Lapsed previously, now restarting
                    currentStreak = 1
                }
            } else {
                // First ever streak day
                currentStreak = 1
            }

            bestStreak = max(bestStreak, currentStreak)
            lastCompletedDate = now
        }

        saveStreakData()
    }

    // MARK: - Past 7 Days Status

    public var past7Days: [WeeklyDayStatus] {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)

        var days: [WeeklyDayStatus] = []
        let dayLetterFormatter = DateFormatter()
        dayLetterFormatter.dateFormat = "EEEEE" // M, T, W, etc.

        for offset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let dateStr = dateFormatter.string(from: date)
            let isToday = calendar.isDateInToday(date)
            let isPast = date < today
            let isCompleted = completedDates.contains(dateStr)
            let letter = dayLetterFormatter.string(from: date)

            days.append(WeeklyDayStatus(
                date: date,
                dateString: dateStr,
                dayLetter: letter,
                isToday: isToday,
                isCompleted: isCompleted,
                isPast: isPast
            ))
        }

        return days
    }
}
