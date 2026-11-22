//
//  ExerciseListView.swift
//  Lucid2.0
//
//  Main scrollable view for the Train tab, laid out Apple-Music-style:
//  Today (hero) → Up Next → Eye Exercises → Neck Exercises → Vision Tests
//

import SwiftUI

public struct ExerciseListView: View {
    @State private var scoreEngine = LucidScoreEngine.shared
    @State private var scheduler = DailyExerciseScheduler.shared

    // Sheet state
    @State private var selectedExercise: ExerciseDefinition?
    @State private var selectedTest: TestDefinition?
    @State private var activeExercise: ExerciseDefinition?
    @State private var activeTest: TestDefinition?

    public init() {}

    // MARK: - Computed

    /// The single next exercise in today's personalized stack — the Apple-Music-style "Today" hero pick.
    private var todayExercise: ExerciseDefinition? {
        scheduler.currentStack.currentExercise
    }

    /// Everything left in today's stack after the hero pick.
    private var upNextExercises: [ExerciseDefinition] {
        let items = scheduler.currentStack.items
        let index = scheduler.currentStack.currentIndex
        guard index < items.count else { return [] }
        return items[(index + 1)...].map(\.exercise)
    }

    /// Ids of exercises in today's personalized plan, used to highlight them wherever they appear.
    private var personalizedIds: Set<String> {
        Set(scheduler.currentStack.items.map(\.exercise.id))
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            // MARK: - Today (Hero)
            if let today = todayExercise {
                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader(icon: "star.fill", title: "Today", subtitle: "Tailored to your plan")

                    TodayHeroCard(
                        exercise: today,
                        onStart: { activeExercise = today },
                        onInfo: { selectedExercise = today }
                    )
                    .padding(.horizontal, 22)
                }
            }

            // MARK: - Up Next
            if !upNextExercises.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(icon: "list.bullet", title: "Up Next", subtitle: "\(upNextExercises.count) more today")

                    VStack(spacing: 10) {
                        ForEach(upNextExercises) { exercise in
                            RecommendedExerciseCard(
                                exercise: exercise,
                                onTap: { activeExercise = exercise },
                                onInfo: { selectedExercise = exercise }
                            )
                            .padding(.horizontal, 22)
                        }
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
                subtitle: "\(ExerciseDefinition.eyeExercises.count) exercises"
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ExerciseDefinition.eyeExercises) { exercise in
                        ExerciseCard(
                            exercise: exercise,
                            isRecommended: personalizedIds.contains(exercise.id),
                            onTap: { activeExercise = exercise },
                            onInfo: { selectedExercise = exercise }
                        )
                    }
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 2)
            }

            // MARK: - Neck Exercises
            SectionHeader(
                icon: "figure.walk",
                title: "Neck Exercises",
                subtitle: "\(ExerciseDefinition.neckExercises.count) exercises"
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ExerciseDefinition.neckExercises) { exercise in
                        ExerciseCard(
                            exercise: exercise,
                            isRecommended: personalizedIds.contains(exercise.id),
                            onTap: { activeExercise = exercise },
                            onInfo: { selectedExercise = exercise }
                        )
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
                subtitle: "\(TestDefinition.catalog.count) tests"
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
        // Exercise detail sheet — reached only via the explicit info (ⓘ) affordance on a card
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        activeTest = test
                    }
                },
                onDismiss: {
                    selectedTest = nil
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .presentationBackground(Color(red: 0.05, green: 0.06, blue: 0.12))
        }
        .fullScreenCover(item: $activeTest) { test in
            TestSessionView(mode: .single(test), onDismiss: { activeTest = nil })
        }
    }

    private func completeExerciseIfItIsToday(_ exercise: ExerciseDefinition) {
        if scheduler.currentStack.currentExercise?.id == exercise.id {
            scheduler.completeCurrentExercise(score: 0.95)
            scoreEngine.updateExerciseProgress(stack: scheduler.currentStack)
        } else {
            StreakManager.shared.recordExerciseCompleted(exerciseId: exercise.id)
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
