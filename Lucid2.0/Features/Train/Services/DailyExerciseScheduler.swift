//
//  DailyExerciseScheduler.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import Foundation
import SwiftUI

@MainActor
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

        // Generate fresh stack for today based on the user's personalized plan
        self.currentStack = generatePersonalizedStack()
        persistStack()
    }

    /// Builds today's stack from the user's onboarding-derived exercise list (`UserProfile.recommendedExerciseIds`),
    /// ordered so exercises matching the current time-of-day slot surface first. Falls back to a generic
    /// time-of-day default only when no personalization exists yet (e.g. onboarding hasn't run).
    private func generatePersonalizedStack() -> DailyExerciseStack {
        let profile = SupabaseService.shared.currentProfile ?? SupabaseService.shared.loadLocalProfile()
        let personalizedExercises = (profile?.recommendedExerciseIds ?? []).compactMap { id in
            ExerciseDefinition.catalog.first { $0.id == id }
        }

        let exercises = personalizedExercises.isEmpty
            ? defaultExercises(for: currentSlot)
            : orderedForCurrentSlot(personalizedExercises)

        let items = exercises.map { DailyExerciseItem(exercise: $0) }
        return DailyExerciseStack(date: Date(), items: items)
    }

    /// Surfaces exercises matching the current time slot (or marked `.anytime`) first, without dropping
    /// any personalized exercise that doesn't match the slot right now.
    private func orderedForCurrentSlot(_ exercises: [ExerciseDefinition]) -> [ExerciseDefinition] {
        let slot = currentSlot
        return exercises.sorted { lhs, rhs in
            let lhsMatches = lhs.idealTimeSlot == slot || lhs.idealTimeSlot == .anytime
            let rhsMatches = rhs.idealTimeSlot == slot || rhs.idealTimeSlot == .anytime
            return lhsMatches && !rhsMatches
        }
    }

    private func defaultExercises(for slot: TimeOfDaySlot) -> [ExerciseDefinition] {
        switch slot {
        case .morning:
            return [.smoothPursuits, .blinkTraining]
        case .midday:
            return [.neckMobility, .nearFarFocus]
        case .evening, .anytime:
            return [.figure8, .pencilPushup]
        }
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

        let completedExerciseId = currentStack.items[index].exercise.id
        persistStack()

        // Sync with StreakManager
        StreakManager.shared.recordExerciseCompleted(exerciseId: completedExerciseId)
    }

    public func resetDailyStack() {
        self.currentStack = generatePersonalizedStack()
        persistStack()
    }
}
