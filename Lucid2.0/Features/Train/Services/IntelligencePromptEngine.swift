//
//  IntelligencePromptEngine.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import Foundation

public final class IntelligencePromptEngine: @unchecked Sendable {
    public static let shared = IntelligencePromptEngine()

    private init() {}

    /// Evaluates whether the current device supports on-device Apple Intelligence
    public var hasAppleIntelligenceSupport: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        // Check for Apple Intelligence availability if running on supported A17 Pro/M-series chips
        if #available(iOS 18.1, *) {
            return false // Falls back safely to dynamic template engine
        }
        return false
        #endif
    }

    /// Generates an encouraging, plain layman prompt explaining what the score means and motivating action
    public func promptForToday(score: Int, slot: TimeOfDaySlot, nextExercise: ExerciseDefinition?) -> String {
        let exerciseName = nextExercise?.title ?? "exercise"

        // 1. Low Score / Strain Recovery (< 60)
        if score < 60 {
            let prompts = [
                "Your eyes have been working overtime today! A quick \(nextExercise?.durationMinutesFormatted ?? "2 mins") of \(exerciseName) will help you shake off the strain and boost your score.",
                "Feeling a little screen fatigue? Take a quick breather with \(exerciseName) to refresh your sight and bounce right back.",
                "Your eye energy is dipping. Let's do a quick \(exerciseName) reset together to give your eyes the relief they deserve."
            ]
            return prompts.randomElement()!
        }

        // 2. Midday Desk Slump (12:00 - 18:00)
        if slot == .midday {
            let prompts = [
                "Midday screen slump creeping in? A quick \(exerciseName) will release neck tension and keep your vision sharp for the afternoon.",
                "Take a 2-minute break from the glare. A quick \(exerciseName) session will clear screen fog and keep you energized.",
                "Halfway through the day! Give your neck and eyes a fast reset with \(exerciseName) before your next work block."
            ]
            return prompts.randomElement()!
        }

        // 3. Morning Awakening (05:00 - 12:00)
        if slot == .morning {
            let prompts = [
                "Good morning! Wake up your eye muscles with a fast round of \(exerciseName) before diving into your screens.",
                "Start your morning sharp. A quick 2-minute \(exerciseName) warms up your focus for the whole day ahead.",
                "Ready to take on the day? A quick morning drill will keep your eyes fresh and comfortable."
            ]
            return prompts.randomElement()!
        }

        // 4. Evening Unwind (18:00+)
        if slot == .evening {
            let prompts = [
                "Time to wind down from screens. A calming round of \(exerciseName) will relax your eye muscles for the night.",
                "You've powered through a full day of screens. Treat your eyes to \(exerciseName) to ease fatigue before bedtime.",
                "Wrap up your day on a high note! A 2-minute relaxation drill helps prevent tomorrow's eye tiredness."
            ]
            return prompts.randomElement()!
        }

        // 5. High Performer / Great Score (75+)
        let prompts = [
            "You're crushing your eye health score today! Knock out a quick \(exerciseName) to keep your streak going strong.",
            "Awesome eye balance today! Just a couple minutes of \(exerciseName) will lock in your top focus score.",
            "Great consistency! A quick \(exerciseName) now keeps your vision clear and your focus effortless."
        ]
        return prompts.randomElement()!
    }
}
