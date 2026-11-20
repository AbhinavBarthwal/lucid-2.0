//
//  ProtectView.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//
//  The "Protect" / Timer tab: preventive-care hub. Today this hosts the
//  20-20-20 screen break — a DeviceActivity usage-threshold reminder that
//  nudges the user after a chosen amount of screen time, plus an on-demand
//  "Start Now" entry into the 20-20-20 lotus exercise.
//

import SwiftUI
import FamilyControls

@available(iOS 26.0, *)
public struct ProtectView: View {
    @State private var viewModel = ScreenBreakViewModel()
    @Environment(\.scenePhase) private var scenePhase

    public init() {}

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    header

                    screenBreakCard

                    startNowCard

                    tipsCard
                }
                .padding(.horizontal, 22)
                .padding(.top, 24)
                .padding(.bottom, 130)
            }
            .scrollIndicators(.hidden)
        }
        .onAppear { viewModel.refreshAuthorization() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { viewModel.refreshAuthorization() }
        }
        .onChange(of: NotificationRouter.shared.pendingRoute) { _, route in
            guard route == .screenBreak else { return }
            viewModel.beginNow()
            NotificationRouter.shared.pendingRoute = .none
        }
        .fullScreenCover(isPresented: $viewModel.showLotus) {
            TwentyTwentyLotusView {
                viewModel.showLotus = false
                viewModel.applySettings()
            }
        }
        .familyActivityPicker(isPresented: $viewModel.showAppPicker, selection: $viewModel.selection)
        .onChange(of: viewModel.selection) { _, _ in
            viewModel.applySettings()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "shield.fill")
                .font(Typography.hero(size: 44, relativeTo: .largeTitle))
                .foregroundStyle(Palette.warmGradient)

            Text("Care & Protection")
                .font(Typography.title2(weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Preventive routines to protect your eyes from digital strain.")
                .font(Typography.subheadline())
                .foregroundStyle(Color.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 4)
    }

    // MARK: - 20-20-20 Settings Card

    private var screenBreakCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "eye.trianglebadge.exclamationmark.fill")
                    .font(Typography.headline())
                    .foregroundStyle(Palette.warmGradient)
                Text("20-20-20 Reminders")
                    .font(Typography.headline(weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { viewModel.isEnabled },
                    set: { newValue in
                        viewModel.isEnabled = newValue
                        if newValue, !viewModel.hasSelection {
                            viewModel.showAppPicker = true
                        }
                        viewModel.applySettings()
                    }
                ))
                .labelsHidden()
                .tint(Palette.amber)
            }

            Text("Every 20-120 minutes of screen time, we'll nudge you to look 20 feet away for 20 seconds.")
                .font(Typography.subheadline())
                .foregroundStyle(Color.white.opacity(0.65))
                .fixedSize(horizontal: false, vertical: true)

            if !viewModel.isAuthorized {
                authorizationRow
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Remind me after")
                        .font(Typography.subheadline(weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                    Spacer()
                    Text(viewModel.intervalFormatted)
                        .font(Typography.subheadline(weight: .bold))
                        .foregroundStyle(Palette.amber)
                }

                Slider(
                    value: Binding(
                        get: { viewModel.intervalMinutes },
                        set: { viewModel.intervalMinutes = $0 }
                    ),
                    in: ScreenBreakViewModel.minIntervalMinutes...ScreenBreakViewModel.maxIntervalMinutes,
                    step: 5,
                    onEditingChanged: { editing in
                        if !editing { viewModel.applySettings() }
                    }
                )
                .tint(Palette.amber)
            }

            Button {
                viewModel.showAppPicker = true
            } label: {
                HStack {
                    Image(systemName: "square.grid.2x2.fill")
                        .foregroundStyle(Palette.amber)
                    Text("Apps to monitor")
                        .font(Typography.subheadline(weight: .medium))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(viewModel.selectionSummary)
                        .font(Typography.subheadline())
                        .foregroundStyle(Color.white.opacity(0.6))
                    Image(systemName: "chevron.right")
                        .font(Typography.caption(weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.4))
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                )
            }
            .buttonStyle(.plain)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(Typography.caption())
                    .foregroundStyle(.red.opacity(0.85))
            }
        }
        .padding(20)
        .cardBackground(top: Palette.cardTop, bottom: Palette.cardBottom)
    }

    private var authorizationRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Screen Time Access Needed")
                    .font(Typography.subheadline(weight: .semibold))
                    .foregroundStyle(.white)
                Text("Required to count usage toward your break reminders.")
                    .font(Typography.caption2())
                    .foregroundStyle(.white.opacity(0.55))
            }
            Spacer()
            Button("Enable") {
                Task { await viewModel.requestAuthorization() }
            }
            .font(Typography.caption(weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(.white.opacity(0.12)))
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(.white.opacity(0.04)))
    }

    // MARK: - Start Now Card

    private var startNowCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "leaf.fill")
                    .font(Typography.headline())
                    .foregroundStyle(Palette.warmGradient)
                Text("Do it right now")
                    .font(Typography.headline(weight: .bold))
                    .foregroundStyle(.white)
            }

            Text("Look 20 feet away for 20 seconds. We'll guide you through it with a 20-petal timer.")
                .font(Typography.subheadline())
                .foregroundStyle(Color.white.opacity(0.65))
                .fixedSize(horizontal: false, vertical: true)

            PulsingActionButton(title: "Start 20-20-20", systemImage: "eye.fill") {
                viewModel.beginNow()
            }
        }
        .padding(20)
        .cardBackground(top: Palette.cardTop, bottom: Palette.cardBottom)
    }

    // MARK: - Tips Card

    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .font(Typography.headline())
                    .foregroundStyle(Palette.warmGradient)
                Text("Other Preventive Habits")
                    .font(Typography.headline(weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 10) {
                preventiveTipRow(symbol: "sun.max.fill", text: "Match your screen brightness to the room around you.")
                preventiveTipRow(symbol: "ruler.fill", text: "Keep screens at least an arm's length from your eyes.")
                preventiveTipRow(symbol: "humidity.fill", text: "Blink fully and often — screens cut your blink rate in half.")
            }
        }
        .padding(20)
        .cardBackground(top: Palette.cardTop, bottom: Palette.cardBottom)
    }

    private func preventiveTipRow(symbol: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(Typography.subheadline())
                .foregroundStyle(Palette.amber)
                .frame(width: 20)
            Text(text)
                .font(Typography.subheadline())
                .foregroundStyle(Color.white.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

@available(iOS 26.0, *)
#Preview {
    ProtectView()
}
