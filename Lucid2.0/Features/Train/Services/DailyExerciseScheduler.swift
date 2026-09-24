//
//  DailyExerciseScheduler.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import Foundation
import SwiftUI

@Observable
public final class DailyExerciseScheduler {
    public static let shared = DailyExerciseScheduler()

    public var currentStack: DailyExerciseStack = DailyExerciseStack()
    public var lastUpdated: Date = Date()

    private let storageKey = "lucid_daily_exercise_stack"

    public init() {
        loadOrGenerateDailyStack()
    }

    // MARK: - Time of Day Slot

    public var currentSlot: TimeOfDaySlot {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return .morning
        case 12..<18:
            return .midday
        default:
            return .evening
        }
    }

    // MARK: - Stack Generation & Persistence

    public func loadOrGenerateDailyStack() {
        let calendar = Calendar.current
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let savedStack = try? JSONDecoder().decode(DailyExerciseStack.self, from: data) {
            // Check if saved stack is from today
            if calendar.isDateInToday(savedStack.date) {
                self.currentStack = savedStack
                return
            }
        }

        // Generate fresh stack for today based on current time slot
        self.currentStack = generateStackForCurrentTime()
        persistStack()
    }

    private func generateStackForCurrentTime() -> DailyExerciseStack {
        var exercises: [ExerciseDefinition] = []

        switch currentSlot {
        case .morning:
            exercises = [
                .smoothPursuits,
                .blinkTraining
            ]
        case .midday:
            exercises = [
                .neckMobility,
                .nearFarFocus
            ]
        case .evening, .anytime:
            exercises = [
                .figure8,
                .pencilPushup
            ]
        }

        let items = exercises.map { DailyExerciseItem(exercise: $0) }
        return DailyExerciseStack(date: Date(), items: items)
    }

    private func persistStack() {
        if let data = try? JSONEncoder().encode(currentStack) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
        self.lastUpdated = Date()
    }

    // MARK: - Progress Operations

    public func completeCurrentExercise(score: Double? = nil) {
        let index = currentStack.currentIndex
        guard index < currentStack.items.count else { return }

        currentStack.items[index].isCompleted = true
        currentStack.items[index].completedAt = Date()
        currentStack.items[index].accuracyScore = score

        persistStack()
    }

    public func resetDailyStack() {
        self.currentStack = generateStackForCurrentTime()
        persistStack()
    }
}
