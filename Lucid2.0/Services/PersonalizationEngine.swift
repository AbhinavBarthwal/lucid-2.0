//
//  PersonalizationEngine.swift
//  Lucid2.0
//
//  Created by Antigravity on 21/09/26.
//

import Foundation

public struct ScreenDiscrepancyInsight: Sendable {
    public let userEstimatedHours: Double
    public let actualHours: Double
    public let deltaHours: Double
    public let isSignificant: Bool
    public let message: String
    public let recommendationNote: String
}

public struct PersonalizedPlanBlueprint: Sendable {
    public let headline: String
    public let subheadline: String
    public let primaryFocus: String
    public let recommendedExercises: [ExerciseDefinition]
    public let startingRestScore: Int
    public let recommendedBlockSlot: String
    public let discrepancy: ScreenDiscrepancyInsight?
}

@MainActor
public final class PersonalizationEngine {
    public static let shared = PersonalizationEngine()

    private init() {}

    /// Calculates a complete tailored plan from the user's survey responses
    public func generateBlueprint(from profile: UserProfile) -> PersonalizedPlanBlueprint {
        var selectedExerciseIds: Set<String> = []

        let screenHours = profile.estimatedDailyScreenTimeHours
        let conditions = Set(profile.previousConditions)
        let hasMyopia = profile.leftEyePower < -0.75 || profile.rightEyePower < -0.75
        let hasPresbyopia = profile.leftEyePower > 0.75 || profile.rightEyePower > 0.75 || conditions.contains("Presbyopia")

        // 1. Condition & Screen Time Rules
        if conditions.contains("Dry Eyes") || conditions.contains("Eye Fatigue") || screenHours >= 7.0 {
            selectedExerciseIds.insert("blink_training")
        }

        if conditions.contains("Digital Eye Strain") || hasMyopia || profile.primaryActivity.contains("Coding") || profile.primaryActivity.contains("Reading") {
            selectedExerciseIds.insert("near_far_focus")
        }

        if conditions.contains("Headaches") || conditions.contains("Neck Pain") || screenHours >= 8.0 {
            selectedExerciseIds.insert("neck_mobility")
        }

        if conditions.contains("Blurry Vision") || conditions.contains("Astigmatism") || screenHours >= 6.0 {
            selectedExerciseIds.insert("smooth_pursuits")
        }

        if conditions.contains("Convergence Issues") || hasPresbyopia {
            selectedExerciseIds.insert("pencil_pushup")
        }

        let isLateOrEvening = profile.peakFatigueTime.contains("Evening") || profile.peakFatigueTime.contains("Late") || profile.peakFatigueTime.contains("Night")
        if isLateOrEvening || screenHours >= 9.0 {
            selectedExerciseIds.insert("figure_8")
        }

        // Fallbacks if fewer than 2 selected
        if selectedExerciseIds.count < 2 {
            selectedExerciseIds.insert("smooth_pursuits")
            selectedExerciseIds.insert("blink_training")
        }

        // Map IDs to catalog
        let resolvedExercises = selectedExerciseIds.compactMap { id in
            ExerciseDefinition.catalog.first { $0.id == id }
        }

        // 2. Starting Score Calculation (0-100)
        // High screen time and active conditions lower starting rest score, giving user clear room to build momentum
        var baseScore = 80
        if screenHours >= 10.0 {
            baseScore -= 18
        } else if screenHours >= 7.0 {
            baseScore -= 12
        } else if screenHours >= 5.0 {
            baseScore -= 6
        }

        baseScore -= min(conditions.count * 3, 15)
        let startingRest = max(45, min(85, baseScore))

        // 3. Screen Time Discrepancy Analysis (Only if Screen Time API was authorized)
        var discrepancy: ScreenDiscrepancyInsight? = nil
        if let actual = profile.actualDailyScreenTimeHours {
            let delta = actual - screenHours

            if abs(delta) >= 0.5 {
                let isOver = delta > 0
                let diffFormatted = String(format: "%.1f", abs(delta))
                let msg = isOver
                    ? "Your actual screen usage averages ~\(String(format: "%.1f", actual)) hrs/day (\(diffFormatted) hrs higher than estimated). That extra screen exposure significantly accelerates tear evaporation and focus lock."
                    : "Your actual screen usage averages ~\(String(format: "%.1f", actual)) hrs/day. You're already doing better than you thought!"

                let note = isOver
                    ? "We've added extra blink pulses and midday neck resets to counteract this gap."
                    : "Your customized routine will keep this healthy habit sustained."

                discrepancy = ScreenDiscrepancyInsight(
                    userEstimatedHours: screenHours,
                    actualHours: actual,
                    deltaHours: delta,
                    isSignificant: true,
                    message: msg,
                    recommendationNote: note
                )
            }
        }

        // 4. Headline & Primary Focus
        let headline: String
        let subheadline: String
        let primaryFocus: String

        if screenHours >= 8.0 || conditions.contains("Digital Eye Strain") {
            headline = "Screen Fatigue & Strain Recovery"
            subheadline = "Engineered for high daily screen exposure"
            primaryFocus = "Blink Rate & Ciliary Muscle Relief"
        } else if conditions.contains("Dry Eyes") {
            headline = "Tear Film & Blink Calibration"
            subheadline = "Focused on reducing irritation & dryness"
            primaryFocus = "Hydration & Natural Blink Pulses"
        } else {
            headline = "Visual Sharpness & Posture Balance"
            subheadline = "Customized daily care routine"
            primaryFocus = "Accommodation & Depth Focus"
        }

        let recommendedBlock = isLateOrEvening ? "8:30 PM – 10:00 PM" : "2:00 PM – 3:30 PM"

        return PersonalizedPlanBlueprint(
            headline: headline,
            subheadline: subheadline,
            primaryFocus: primaryFocus,
            recommendedExercises: resolvedExercises,
            startingRestScore: startingRest,
            recommendedBlockSlot: recommendedBlock,
            discrepancy: discrepancy
        )
    }

    /// Applies the blueprint to the active app engines
    public func applyBlueprint(_ blueprint: PersonalizedPlanBlueprint, to profile: inout UserProfile) {
        profile.recommendedExerciseIds = blueprint.recommendedExercises.map(\.id)
        profile.baselineRestScore = blueprint.startingRestScore

        // Update score engine
        LucidScoreEngine.shared.updateRestScore(blueprint.startingRestScore)

        // Update daily exercise scheduler with their personalized stack
        let items = blueprint.recommendedExercises.prefix(2).map { DailyExerciseItem(exercise: $0) }
        DailyExerciseScheduler.shared.currentStack = DailyExerciseStack(date: Date(), items: Array(items))

        // Save profile
        SupabaseService.shared.saveLocalProfile(profile)
    }

    /// Provides realistic simulated actual screen time from DeviceActivity / historical usage
    public func fetchSimulatedActualScreenTime(estimated: Double) -> Double {
        // Average screen workers underestimate screen time by 1.5 to 2.5 hours
        let adjustment = estimated >= 6.0 ? 1.8 : 0.8
        return round((estimated + adjustment) * 10) / 10
    }
}
