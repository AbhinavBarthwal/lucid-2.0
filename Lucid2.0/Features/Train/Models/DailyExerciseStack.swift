//
//  DailyExerciseStack.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import Foundation

public struct DailyExerciseItem: Identifiable, Codable, Hashable, Sendable {
    public var id: String { exercise.id }
    public let exercise: ExerciseDefinition
    public var isCompleted: Bool
    public var completedAt: Date?
    public var accuracyScore: Double?

    public init(
        exercise: ExerciseDefinition,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        accuracyScore: Double? = nil
    ) {
        self.exercise = exercise
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.accuracyScore = accuracyScore
    }
}

public struct DailyExerciseStack: Codable, Sendable {
    public var date: Date
    public var items: [DailyExerciseItem]

    public init(date: Date = Date(), items: [DailyExerciseItem] = []) {
        self.date = date
        self.items = items
    }

    public var totalCount: Int {
        items.count
    }

    public var completedCount: Int {
        items.filter { $0.isCompleted }.count
    }

    public var isCompleted: Bool {
        totalCount > 0 && completedCount == totalCount
    }

    public var currentIndex: Int {
        items.firstIndex(where: { !$0.isCompleted }) ?? items.count
    }

    public var currentExercise: ExerciseDefinition? {
        guard currentIndex < items.count else { return nil }
        return items[currentIndex].exercise
    }

    public var hasStarted: Bool {
        completedCount > 0 && !isCompleted
    }

    public var remainingDurationSeconds: Int {
        items.filter { !$0.isCompleted }.reduce(0) { $0 + $1.exercise.estimatedDurationSeconds }
    }

    public var remainingDurationFormatted: String {
        let mins = max(1, Int(ceil(Double(remainingDurationSeconds) / 60.0)))
        return "\(mins) min\(mins == 1 ? "" : "s")"
    }

    public var progressFraction: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }
}
