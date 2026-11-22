//
//  PersonalizationEngine.swift
//  Lucid2.0
//
//  Created by Antigravity on 21/09/26.
//

import Foundation

public struct PersonalizedPlanBlueprint: Sendable {
    public let headline: String
    public let subheadline: String
    public let primaryFocus: String
    public let recommendedExercises: [ExerciseDefinition]
    public let startingRestScore: Int
    public let recommendedBlockSlot: String
}

@MainActor
public final class PersonalizationEngine {
    public static let shared = PersonalizationEngine()

    private init() {}

    /// Calculates a complete tailored plan from the user's survey responses
    public func generateBlueprint(from profile: UserProfile) -> PersonalizedPlanBlueprint {
        // Ordered + de-duplicated so the same answers always produce the same plan in the same order
        // (a Set here previously made exercise order change randomly between launches).
        var selectedExerciseIds: [String] = []
        func select(_ id: String) {
            guard !selectedExerciseIds.contains(id) else { return }
            selectedExerciseIds.append(id)
        }

        let screenHours = profile.estimatedDailyScreenTimeHours
        let conditions = Set(profile.previousConditions)
        let hasMyopia = profile.leftEyePower < -0.75 || profile.rightEyePower < -0.75
        let hasPresbyopia = profile.leftEyePower > 0.75 || profile.rightEyePower > 0.75 || conditions.contains("Presbyopia")

        // 1. Condition & Screen Time Rules
        // NOTE: `previousConditions` stores the exact onboarding option strings, so matches must
        // use those exact values (e.g. the compound "Headaches / Neck Pain"), not substrings of them.
        if conditions.contains("Dry Eyes") || screenHours >= 7.0 {
            select("blink_training")
        }

        if conditions.contains("Light Sensitivity") {
            select("blink_training")
        }

        if conditions.contains("Digital Eye Strain") || hasMyopia || profile.primaryActivity.contains("Coding") || profile.primaryActivity.contains("Reading") {
            select("near_far_focus")
        }

        if conditions.contains("Headaches / Neck Pain") || screenHours >= 8.0 {
            select("neck_mobility")
        }

        if conditions.contains("Blurry Vision") || screenHours >= 6.0 {
            select("smooth_pursuits")
        }

        if conditions.contains("Blurry Vision") || conditions.contains("Eye Fatigue") {
            select("figure_8")
        }

        if conditions.contains("Astigmatism") {
            select("saccadic_jumps")
        }

        if conditions.contains("Convergence Issues") || hasPresbyopia {
            select("pencil_pushup")
        }

        let isLateOrEvening = profile.peakFatigueTime.contains("Evening") || profile.peakFatigueTime.contains("Late") || profile.peakFatigueTime.contains("Night")
        if isLateOrEvening || screenHours >= 9.0 {
            select("figure_8")
        }

        // Fallbacks if fewer than 2 selected
        if selectedExerciseIds.count < 2 {
            select("smooth_pursuits")
            select("blink_training")
        }

        // Map IDs to catalog, preserving selection order
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

        // 3. Headline & Primary Focus
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
            recommendedBlockSlot: recommendedBlock
        )
    }

    /// Applies the blueprint to the active app engines
    public func applyBlueprint(_ blueprint: PersonalizedPlanBlueprint, to profile: inout UserProfile) {
        profile.recommendedExerciseIds = blueprint.recommendedExercises.map(\.id)
        profile.baselineRestScore = blueprint.startingRestScore

        // Update score engine
        LucidScoreEngine.shared.updateRestScore(blueprint.startingRestScore)

        // Update daily exercise scheduler with their full personalized stack (previously
        // truncated to 2, silently dropping exercises the plan-reveal screen had already promised).
        let items = blueprint.recommendedExercises.map { DailyExerciseItem(exercise: $0) }
        DailyExerciseScheduler.shared.currentStack = DailyExerciseStack(date: Date(), items: items)

        // Save profile
        SupabaseService.shared.saveLocalProfile(profile)
    }
}
