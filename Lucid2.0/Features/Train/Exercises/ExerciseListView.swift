//
//  ExerciseListView.swift
//  Lucid2.0
//
//  Main scrollable view for the Train tab.
//  Sections: Recommended → Eye Exercises → Neck → Vision Tests
//

import SwiftUI

public struct ExerciseListView: View {
    @State private var scoreEngine = LucidScoreEngine.shared
    @State private var scheduler = DailyExerciseScheduler.shared

    // Sheet state
    @State private var selectedExercise: ExerciseDefinition?
    @State private var selectedTest: TestDefinition?
    @State private var activeExercise: ExerciseDefinition?

    public init() {}

    // MARK: - Computed

    private var recommendedExercises: [ExerciseDefinition] {
        let score = scoreEngine.overallScore
        let slot = scheduler.currentSlot
        var ids: [String] = []

        if score < 60 {
            ids = ["smooth_pursuits", "saccadic_jumps"]
        } else if scoreEngine.testScore < 65 {
            ids = ["blink_training", "near_far_focus"]
        } else {
            switch slot {
            case .morning:
                ids = ["smooth_pursuits", "blink_training"]
            case .midday:
                ids = ["neck_mobility", "near_far_focus"]
            case .evening, .anytime:
                ids = ["figure_8", "pencil_pushup"]
            }
        }

        return ids.compactMap { id in
            ExerciseDefinition.catalog.first { $0.id == id }
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // MARK: - Recommended Section
            if !recommendedExercises.isEmpty {
                SectionHeader(
                    icon: "star.fill",
                    title: "Recommended",
                    subtitle: "Tailored to your score today"
                )

                VStack(spacing: 10) {
                    ForEach(recommendedExercises) { exercise in
                        RecommendedExerciseCard(exercise: exercise) {
                            selectedExercise = exercise
                        }
                        .padding(.horizontal, 22)
                    }
                }

                Divider()
                    .background(Color.white.opacity(0.08))
                    .padding(.horizontal, 22)
                    .padding(.top, 4)
            }

            // MARK: - Eye Exercises
            SectionHeader(
                icon: "eye.fill",
                title: "Eye Exercises",
                subtitle: ""
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ExerciseDefinition.eyeExercises) { exercise in
                        ExerciseCard(exercise: exercise) {
                            selectedExercise = exercise
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 2)
            }

            // MARK: - Neck Exercises
            SectionHeader(
                icon: "figure.walk",
                title: "Neck Exercises",
                subtitle: ""
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ExerciseDefinition.neckExercises) { exercise in
                        ExerciseCard(exercise: exercise) {
                            selectedExercise = exercise
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 2)
            }

            Divider()
                .background(Color.white.opacity(0.08))
                .padding(.horizontal, 22)

            // MARK: - Vision Tests
            SectionHeader(
                icon: "waveform.path.ecg",
                title: "Vision Tests",
                subtitle: ""
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(TestDefinition.catalog) { test in
                        TestCard(test: test) {
                            selectedTest = test
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 2)
            }

            // Bottom safe-area padding for tab bar
            Color.clear.frame(height: 130)
        }
        // Exercise detail sheet
        .sheet(item: $selectedExercise) { exercise in
            ExerciseDetailSheet(
                exercise: exercise,
                onStart: {
                    selectedExercise = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        activeExercise = exercise
                    }
                },
                onDismiss: {
                    selectedExercise = nil
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .presentationBackground(Color(red: 0.05, green: 0.06, blue: 0.12))
        }
        .fullScreenCover(item: $activeExercise) { exercise in
            ExerciseSessionView(
                exercise: exercise,
                onCompleted: {
                    completeExerciseIfItIsToday(exercise)
                    activeExercise = nil
                },
                onDismiss: {
                    activeExercise = nil
                }
            )
        }
        // Test detail sheet
        .sheet(item: $selectedTest) { test in
            TestDetailSheet(
                test: test,
                onStart: {
                    selectedTest = nil
                    // Future: navigate into test session
                },
                onDismiss: {
                    selectedTest = nil
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .presentationBackground(Color(red: 0.05, green: 0.06, blue: 0.12))
        }
    }

    private func completeExerciseIfItIsToday(_ exercise: ExerciseDefinition) {
        if scheduler.currentStack.currentExercise?.id == exercise.id {
            scheduler.completeCurrentExercise(score: 0.95)
            scoreEngine.updateExerciseProgress(stack: scheduler.currentStack)
        } else {
            scoreEngine.updateExerciseProgress(stack: scheduler.currentStack)
        }
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(Typography.footnote(weight: .semibold))
                    .foregroundStyle(Palette.amber)

                Text(title)
                    .font(Typography.headline(weight: .bold))
                    .foregroundStyle(.white)
            }

            Spacer()

            Text(subtitle)
                .font(Typography.caption())
                .foregroundStyle(Color.white.opacity(0.4))
        }
        .padding(.horizontal, 22)
    }
}

#Preview {
    TrainView()
}
