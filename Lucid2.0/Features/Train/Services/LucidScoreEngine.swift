//
//  LucidScoreEngine.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import Foundation
import SwiftUI

@Observable
public final class LucidScoreEngine {
    public static let shared = LucidScoreEngine()

    public var restScore: Int = 74
    public var exerciseScore: Int = 68
    public var testScore: Int = 82

    public var hasCompletedFirstExercise: Bool = false
    public var hasCompletedFirstTest: Bool = false

    private let restKey = "lucid_score_rest"
    private let exerciseKey = "lucid_score_exercise"
    private let testKey = "lucid_score_test"
    private let firstExerciseKey = "lucid_has_completed_first_exercise"
    private let firstTestKey = "lucid_has_completed_first_test"

    public init() {
        loadScores()
    }

    /// Whether the user has completed calibration (at least 1 exercise AND 1 test)
    public var isScoreCalibrated: Bool {
        hasCompletedFirstExercise && hasCompletedFirstTest
    }

    /// Total calibration tasks completed (0, 1, or 2)
    public var calibrationTasksCompleted: Int {
        (hasCompletedFirstExercise ? 1 : 0) + (hasCompletedFirstTest ? 1 : 0)
    }

    /// Overall composite score with equal 1/3 weightage across Rest, Exercise, and Tests (0-100)
    public var overallScore: Int {
        let sum = Double(restScore + exerciseScore + testScore)
        return min(100, max(0, Int(round(sum / 3.0))))
    }

    /// Returns the overall score ONLY if calibrated; otherwise nil (for blurred presentation)
    public var calibratedOverallScore: Int? {
        isScoreCalibrated ? overallScore : nil
    }

    public var calibratedExerciseScore: Int? {
        hasCompletedFirstExercise ? exerciseScore : nil
    }

    public var calibratedTestScore: Int? {
        hasCompletedFirstTest ? testScore : nil
    }

    public var calibratedRestScore: Int? {
        isScoreCalibrated ? restScore : nil
    }

    public var scoreTierDescription: String {
        guard isScoreCalibrated else {
            return "Calibrating Baseline"
        }
        switch overallScore {
        case 85...100:
            return "Optimal Balance"
        case 70..<85:
            return "Healthy Focus"
        case 50..<70:
            return "Mild Strain"
        default:
            return "Fatigue Alert"
        }
    }

    // MARK: - Persistence & Updates

    private func loadScores() {
        if let r = UserDefaults.standard.object(forKey: restKey) as? Int {
            self.restScore = r
        }
        if let e = UserDefaults.standard.object(forKey: exerciseKey) as? Int {
            self.exerciseScore = e
        }
        if let t = UserDefaults.standard.object(forKey: testKey) as? Int {
            self.testScore = t
        }
        self.hasCompletedFirstExercise = UserDefaults.standard.bool(forKey: firstExerciseKey)
        self.hasCompletedFirstTest = UserDefaults.standard.bool(forKey: firstTestKey)
    }

    private func saveScores() {
        UserDefaults.standard.set(restScore, forKey: restKey)
        UserDefaults.standard.set(exerciseScore, forKey: exerciseKey)
        UserDefaults.standard.set(testScore, forKey: testKey)
        UserDefaults.standard.set(hasCompletedFirstExercise, forKey: firstExerciseKey)
        UserDefaults.standard.set(hasCompletedFirstTest, forKey: firstTestKey)
    }

    public func updateRestScore(_ score: Int) {
        self.restScore = min(100, max(0, score))
        saveScores()
    }

    public func markFirstExerciseCompleted() {
        self.hasCompletedFirstExercise = true
        saveScores()
    }

    public func markFirstTestCompleted() {
        self.hasCompletedFirstTest = true
        saveScores()
    }

    public func updateExerciseProgress(stack: DailyExerciseStack) {
        markFirstExerciseCompleted()
        let base = 50.0
        let boost = stack.progressFraction * 45.0
        self.exerciseScore = min(100, max(0, Int(base + boost)))
        saveScores()
    }

    public func recordTestResults(cTestAcuity: Double, osdiScore: Double) {
        markFirstTestCompleted()
        // C-test: normalized relative to standard 6/6 acuity
        let cNormalized = min(100.0, (cTestAcuity / 6.0) * 100.0)
        // OSDI: 0 is healthiest, 100 is severe. Inverted for score
        let osdiNormalized = max(0.0, 100.0 - osdiScore)

        let compositeTest = Int(round((cNormalized + osdiNormalized) / 2.0))
        self.testScore = min(100, max(0, compositeTest))
        saveScores()
    }

    public func resetCalibration() {
        self.hasCompletedFirstExercise = false
        self.hasCompletedFirstTest = false
        saveScores()
    }
}
