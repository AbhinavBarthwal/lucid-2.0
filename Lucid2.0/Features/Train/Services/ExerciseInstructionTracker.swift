//
//  ExerciseInstructionTracker.swift
//  Lucid2.0
//
//  Tracks whether the user has seen instructions for each exercise.
//  First run → show info blurb + "Show Instructions" prominently.
//  Subsequent runs → show "Show Instructions" as ghost + "Start Exercise" CTA.
//

import Foundation

public final class ExerciseInstructionTracker: @unchecked Sendable {
    public static let shared = ExerciseInstructionTracker()

    private let keyPrefix = "lucid_instruction_first_run_"

    private init() {}

    /// Returns true if this is the first time the user is opening this exercise
    public func isFirstRun(for exerciseId: String) -> Bool {
        let key = keyPrefix + exerciseId
        return !UserDefaults.standard.bool(forKey: key)
    }

    /// Call this once the user has completed or started the exercise (after instructions)
    public func markSeen(for exerciseId: String) {
        let key = keyPrefix + exerciseId
        UserDefaults.standard.set(true, forKey: key)
    }

    /// Reset first-run state (useful for debug/testing)
    public func reset(for exerciseId: String) {
        let key = keyPrefix + exerciseId
        UserDefaults.standard.removeObject(forKey: key)
    }
}
