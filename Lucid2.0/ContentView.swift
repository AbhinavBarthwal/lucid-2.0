//
//  ContentView.swift
//  Lucid2.0
//
//  Created by Abhinav Barthwal on 07/09/26.
//

import SwiftUI

public enum AppTab: Hashable {
    case home
    case care
    case timer
}

public struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var selectedTab: AppTab = .home
    @State private var blockingVM = AppBlockingViewModel()

    // Configuration overrides for previews and testing
    private var isOnboardingCompletedOverride: Bool?
    private var scoreEngine: LucidScoreEngine?

    public init(
        isOnboardingCompleted: Bool? = nil,
        selectedTab: AppTab = .home,
        scoreEngine: LucidScoreEngine? = nil
    ) {
        self.isOnboardingCompletedOverride = isOnboardingCompleted
        self._selectedTab = State(initialValue: selectedTab)
        self.scoreEngine = scoreEngine
    }

    private var isUserLoggedIn: Bool {
        isOnboardingCompletedOverride ?? hasCompletedOnboarding
    }

    public var body: some View {
        Group {
            if !isUserLoggedIn {
                OnboardingFlowCoordinator {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        hasCompletedOnboarding = true
                    }
                }
            } else {
                mainAppView
            }
        }
        .preferredColorScheme(.dark)
        .task {
            // Keep local device cache and remote Supabase profile synced
            if isOnboardingCompletedOverride == nil {
                await SupabaseService.shared.syncProfileWithRemote()
            }
        }
        .onChange(of: NotificationRouter.shared.pendingRoute) { _, route in
            switch route {
            case .screenBreak:
                selectedTab = .timer
            case .exercise:
                selectedTab = .home
            case .visionTest:
                selectedTab = .care
            case .none:
                break
            }
        }
    }

    private var mainAppView: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView(
                    blockingVM: blockingVM,
                    scoreEngine: scoreEngine ?? .shared,
                    onOpenCareTab: {
                        selectedTab = .care
                    }
                )
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(AppTab.home)

                TrainView()
                    .tabItem {
                        Label("Care", systemImage: "shield.fill")
                    }
                    .tag(AppTab.care)

                ProtectView()
                    .tabItem {
                        Label("Protect", systemImage: "eye.fill")
                    }
                    .tag(AppTab.timer)
            }
            .tint(Palette.amber)

            // Floating Unblock Pill pinned above the tab bar on Home
            if selectedTab == .home, !blockingVM.blocks.isEmpty {
                UnblockPill(viewModel: blockingVM)
                    .padding(.bottom, 62)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selectedTab)
    }
}

#Preview("Logged In - No Tests or Exercises Completed") {
    let uncalibratedScoreEngine = LucidScoreEngine.uncalibrated

    // Configure a logged-in user profile
    SupabaseService.shared.currentProfile = UserProfile(
        id: UUID(),
        name: "Alex",
        email: "alex@example.com",
        leftEyePower: -1.5,
        rightEyePower: -1.75,
        hasGlassesOrContacts: true,
        previousConditions: ["Eye Strain", "Dry Eyes"],
        estimatedDailyScreenTimeHours: 8.0,
        actualDailyScreenTimeHours: nil,
        primaryActivity: "Coding & Reading",
        peakFatigueTime: "Late Day (5–8)",
        recommendedExerciseIds: ["blink_training", "near_far_focus", "smooth_pursuits"],
        baselineRestScore: 70
    )

    // Ensure tests are due and no exercises or tests have been completed
    TestScheduleManager.shared.resetTestDue()
    DailyExerciseScheduler.shared.resetDailyStack()
    StreakManager.shared.resetStreak()

    return ContentView(
        isOnboardingCompleted: true,
        selectedTab: .home,
        scoreEngine: uncalibratedScoreEngine
    )
}

#Preview("Onboarding Flow (Not Logged In)") {
    ContentView(isOnboardingCompleted: false)
}
