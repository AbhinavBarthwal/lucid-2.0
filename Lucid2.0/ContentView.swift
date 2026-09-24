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

    public init() {}

    public var body: some View {
        Group {
            if !hasCompletedOnboarding {
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
            await SupabaseService.shared.syncProfileWithRemote()
        }
    }

    private var mainAppView: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView(
                    blockingVM: blockingVM,
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
                        Label("Timer", systemImage: "play.circle.fill")
                    }
                    .tag(AppTab.timer)
            }
            .tint(Palette.amber)

            // Floating Unblock Pill pinned above the tab bar on Home
            if selectedTab == .home {
                UnblockPill(viewModel: blockingVM)
                    .padding(.bottom, 62)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selectedTab)
    }
}

#Preview {
    ContentView()
}
