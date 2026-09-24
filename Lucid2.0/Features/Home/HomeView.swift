//
//  HomeView.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import SwiftUI
import UserNotifications

private struct HomeScrollOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

public struct HomeView: View {
    @Bindable public var blockingVM: AppBlockingViewModel
    public var onOpenCareTab: (() -> Void)? = nil

    @Environment(\.scenePhase) private var scenePhase
    @State private var scrollY: CGFloat = 0
    @State private var baseline: CGFloat?
    @State private var showNotificationSetup = false
    @State private var showProfile = false
    @State private var showStreakDetail = false

    // MARK: - Test, Exercise, Score & Streak State
    @State private var testManager = TestScheduleManager.shared
    @State private var exerciseScheduler = DailyExerciseScheduler.shared
    @State private var scoreEngine = LucidScoreEngine.shared
    @State private var streakManager = StreakManager.shared
    @State private var currentPrompt: String = ""
    @State private var activeExercise: ExerciseDefinition?

    public init(blockingVM: AppBlockingViewModel, onOpenCareTab: (() -> Void)? = nil) {
        self.blockingVM = blockingVM
        self.onOpenCareTab = onOpenCareTab
    }

    public var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    ScoreHeroView()

                    VStack(spacing: 18) {
                        // 1. Notification Setup Card (hidden if enabled, suppressed for 15 days if dismissed)
                        if showNotificationSetup {
                            NotificationSetupCard(
                                onEnable: handleEnableNotifications,
                                onDismiss: handleDismissNotifications
                            )
                            .transition(.scale(scale: 0.95).combined(with: .opacity))
                        }

                        // 2. Start Test Card (Top-most actionable card when tests are due - Most Prominent in UI)
                        if testManager.isTestDue {
                            StartTestCard(
                                onStartTest: handleStartTest
                            )
                            .transition(.scale(scale: 0.98).combined(with: .opacity))
                        }

                        // 3. Start Exercise Card (Daily stack, dynamic prompt, duration; prominent if test not due)
                        StartExerciseCard(
                            stack: exerciseScheduler.currentStack,
                            isPrimaryProminence: !testManager.isTestDue,
                            
                            onStartExercise: handleStartExercise
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))

                        // 4. Zone A: App Blocking Card (Setup state vs Care complete state)
                        if blockingVM.blocks.isEmpty {
                            SetUpAppBlocking(viewModel: blockingVM)
                                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                        } else {
                            CareBlockingCard(
                                viewModel: blockingVM,
                                onOpenCareTab: onOpenCareTab
                            )
                            .transition(.opacity.combined(with: .scale(scale: 0.98)))
                        }

                        // 5. Streak Card (Connected to real exercises & interactive sheet)
                        StreakCard()
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 18)
                    .padding(.bottom, 130)
                }
                .background(alignment: .top) {
                    CaveBackground().frame(height: 600)
                }
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(key: HomeScrollOffsetKey.self,
                                               value: geo.frame(in: .global).minY)
                    }
                )
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .top)
            .onPreferenceChange(HomeScrollOffsetKey.self) { y in
                if baseline == nil { baseline = y }
                let delta = min(max((baseline ?? y) - y, 0), 120)
                if delta != scrollY { scrollY = delta }
            }

            // Header fade gradient overlay
            LinearGradient(
                stops: [
                    .init(color: .black, location: 0),
                    .init(color: Color.black.opacity(0.94), location: 0.55),
                    .init(color: Color.black.opacity(0), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 165)
            .opacity(Double(min(scrollY / 100, 1)))
            .allowsHitTesting(false)
            .ignoresSafeArea(edges: .top)

            // Top Header Bar
            HomeHeaderBar(
                streakCount: streakManager.currentStreak,
                onStreakTapped: { showStreakDetail = true },
                onProfileTapped: { showProfile = true }
            )
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: showNotificationSetup)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: testManager.isTestDue)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: exerciseScheduler.currentStack.currentIndex)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: blockingVM.blocks.isEmpty)
        .sheet(isPresented: $blockingVM.showPopup) {
            AppBlockingPopupView(viewModel: blockingVM)
        }
        .sheet(isPresented: $showStreakDetail) {
            StreakDetailSheet()
                .presentationDetents([.fraction(0.85), .large])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(item: $activeExercise) { exercise in
            ExerciseSessionView(
                exercise: exercise,
                onCompleted: {
                    completeActiveExercise()
                    activeExercise = nil
                },
                onDismiss: {
                    activeExercise = nil
                }
            )
        }
        .fullScreenCover(isPresented: $showProfile) {
            ProfileView()
        }
        .onAppear {
            streakManager.refreshStreakState()
            blockingVM.loadBlocks()
            testManager.checkDueStatus()
            exerciseScheduler.loadOrGenerateDailyStack()
            refreshPrompt()
        }
        .task {
            await updateNotificationSetupVisibility()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                streakManager.refreshStreakState()
                Task {
                    await updateNotificationSetupVisibility()
                }
            }
        }
    }

    private var defaultPrompt: String {
        IntelligencePromptEngine.shared.promptForToday(
            score: scoreEngine.overallScore,
            slot: exerciseScheduler.currentSlot,
            nextExercise: exerciseScheduler.currentStack.currentExercise
        )
    }

    private func refreshPrompt() {
        currentPrompt = IntelligencePromptEngine.shared.promptForToday(
            score: scoreEngine.overallScore,
            slot: exerciseScheduler.currentSlot,
            nextExercise: exerciseScheduler.currentStack.currentExercise
        )
    }

    private func handleStartTest() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            // Completes test battery, marks tests done, updates test score and promotes Exercise card to primary!
            testManager.completeTestBattery(cTestScore: 6.0, osdiScore: 12.0)
            refreshPrompt()
        }
    }

    private func handleStartExercise() {
        activeExercise = exerciseScheduler.currentStack.currentExercise
    }

    private func completeActiveExercise() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            exerciseScheduler.completeCurrentExercise(score: 0.95)
            scoreEngine.updateExerciseProgress(stack: exerciseScheduler.currentStack)
            refreshPrompt()
        }
    }

    private func handleEnableNotifications() {
        Task {
            let granted = await NotificationSetupManager.shared.requestAuthorization()
            if granted {
                await MainActor.run {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                        showNotificationSetup = false
                    }
                }
            }
        }
    }

    private func handleDismissNotifications() {
        NotificationSetupManager.shared.markCardDismissed()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            showNotificationSetup = false
        }
    }

    private func updateNotificationSetupVisibility() async {
        let shouldShow = await NotificationSetupManager.shared.shouldShowCard()
        await MainActor.run {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                showNotificationSetup = shouldShow
            }
        }
    }
}

#Preview {
    HomeView(blockingVM: AppBlockingViewModel())
}
