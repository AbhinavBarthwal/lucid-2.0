//
//  StartExerciseCard.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import SwiftUI

public struct StartExerciseCard: View {
    public let stack: DailyExerciseStack
    public let isPrimaryProminence: Bool
 
    public let onStartExercise: () -> Void

    public init(
        stack: DailyExerciseStack,
        isPrimaryProminence: Bool = true,
  
        onStartExercise: @escaping () -> Void
    ) {
        self.stack = stack
        self.isPrimaryProminence = isPrimaryProminence

        self.onStartExercise = onStartExercise
    }

    private var buttonTitle: String {
        if stack.isCompleted {
            return "Exercises Completed"
        } else if stack.hasStarted {
            return "Resume Exercise"
        } else {
            return "Start Exercise"
        }
    }

    private var timeText: String {
        if stack.isCompleted {
            return "Done for today"
        }
        return stack.remainingDurationFormatted
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header Row: Section Label + Time Duration Badge
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "dumbbell.fill")
                        .font(Typography.footnote(weight: .semibold))
                        .foregroundStyle(Palette.amber)

                    Text(stack.hasStarted ? "Daily Exercise" : "Daily Exercise")
                        .font(Typography.headline())
                        .foregroundStyle(.white)
                }

                Spacer()

                // Time it will take badge
                HStack(spacing: 5) {
                    Image(systemName: stack.isCompleted ? "checkmark.circle.fill" : "clock")
                        .font(Typography.caption(weight: .medium))
                        .foregroundStyle(stack.isCompleted ? Color.green : Palette.amber)

                    Text(timeText)
                        .font(Typography.footnote(weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.85))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8))
                )
            }



            // Action Button: Primary (if test not due) vs Secondary (if test due)
            if !stack.isCompleted {
                Button(action: onStartExercise) {
                    HStack(spacing: 8) {
                        Text(buttonTitle)
                            .font(Typography.headline(weight: .bold))
                            .foregroundStyle(isPrimaryProminence ? Color.black : .white)

                        Image(systemName: "arrow.right")
                            .font(Typography.subheadline(weight: .bold))
                            .foregroundStyle(isPrimaryProminence ? Color.black : Palette.amber)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .padding(.vertical, 10)
                    .background {
                        if isPrimaryProminence {
                            RoundedRectangle(cornerRadius: 44, style: .continuous)
                                .fill(Palette.warmGradient)
                                .glassEffect(.clear, in: .capsule)
                                .shadow(color: Palette.ember.opacity(0.45), radius: 14, x: 0, y: 5)
                        } else {
                            RoundedRectangle(cornerRadius: 44, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                                .glassEffect(.clear, in: .capsule)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 44, style: .continuous)
                                        .strokeBorder(Palette.amber.opacity(0.35), lineWidth: 1)
                                )
                        }
                    }
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .cardBackground(top: Palette.cardTop, bottom: Palette.cardBottom, corner: 24)
    }
}

#Preview("Primary Prominence") {
    ZStack {
        Color.black.ignoresSafeArea()
        StartExerciseCard(
            stack: DailyExerciseStack(items: [
                DailyExerciseItem(exercise: .smoothPursuits),
                DailyExerciseItem(exercise: .blinkTraining)
            ]),
            isPrimaryProminence: true,
            
            onStartExercise: {}
        )
        .padding()
    }
}

#Preview("Secondary Prominence (Test is Due)") {
    ZStack {
        Color.black.ignoresSafeArea()
        StartExerciseCard(
            stack: DailyExerciseStack(items: [
                DailyExerciseItem(exercise: .smoothPursuits),
                DailyExerciseItem(exercise: .blinkTraining)
            ]),
            isPrimaryProminence: false,
            
            onStartExercise: {}
        )
        .padding()
    }
}
