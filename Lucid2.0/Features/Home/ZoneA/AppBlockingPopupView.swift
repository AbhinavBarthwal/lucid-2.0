//
//  AppBlockingPopupView.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import SwiftUI
import FamilyControls

public struct AppBlockingPopupView: View {
    @Bindable var viewModel: AppBlockingViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Completion Animation States
    @State private var isShowingCompletionOverlay: Bool = false
    @State private var checkmarkAnimatedIn: Bool = false
    @State private var isFirstSetup: Bool = true

    private enum ActiveTimePicker {
        case none
        case from
        case to
    }
    @State private var activeTimePicker: ActiveTimePicker = .none

    public init(viewModel: AppBlockingViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        // Dependency hook to ensure dynamic re-render on any block/selection updates
        let _ = viewModel.lastUpdated

        ZStack {
            // Translucent glass base layer with card dark tones
            LinearGradient(
                colors: [
                    Palette.inkTop.opacity(0.92),
                    Palette.inkBottom.opacity(0.96),
                    Color.black.opacity(0.98)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .glassEffect(.clear, in: .rect)
            .ignoresSafeArea()

            // Ambient warm background glows
            VStack {
                Spacer()

                RadialGradient(
                    colors: [Palette.blobGlow.opacity(0.22), Color.clear],
                    center: .bottom,
                    startRadius: 0,
                    endRadius: 280
                )
                .frame(height: 220)
                .ignoresSafeArea()
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // Main Layout
            VStack(spacing: 0) {
                // MARK: - Header
                headerView
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                // Divider line and grabber bar
                VStack(spacing: 8) {
                    Divider()
                        .background(Color.white.opacity(0.12))

                    Capsule()
                        .fill(Color.white.opacity(0.22))
                        .glassEffect(.clear, in: .capsule)
                        .frame(width: 36, height: 4)
                        .padding(.top, 2)
                }
                .padding(.bottom, 12)

                // MARK: - Scrollable Form Content
                ZStack(alignment: .bottom) {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Section 1: During this time
                            duringThisTimeSection

                            // Section 2: On these days
                            onTheseDaysSection

                            // Section 3: Apps are blocked
                            appsAreBlockedSection

                            // Section 4: Hard Mode
                            hardModeSection

                            // Buffer space so content never gets obscured by sticky button
                            Spacer()
                                .frame(height: 96)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                    }

                    // MARK: - Sticky Floating Button
                    stickyBottomBar
                }
            }

            // MARK: - Completion Animation Overlay
            if isShowingCompletionOverlay {
                completionOverlayView
            }
        }
        .presentationDetents([.fraction(0.88), .large])
        .presentationCornerRadius(32)
        .presentationDragIndicator(.hidden)
        .presentationBackground {
            ZStack {
                Palette.cardBottom.opacity(0.85)
                Rectangle().fill(.ultraThinMaterial)
            }
            .glassEffect(.clear, in: .rect)
        }
        // Family Activity Picker sheet
        .familyActivityPicker(
            isPresented: $viewModel.showAppPicker,
            selection: $viewModel.draftSelection
        )
        .onChange(of: viewModel.draftSelection) { _, newSelection in
            // Force UI refresh - bump lastUpdated which is observed by the view
            viewModel.lastUpdated = Date()
            #if targetEnvironment(simulator)
            let catCount = AppBlockingViewModel.rawCategoryCount(from: newSelection)
            let appCount = AppBlockingViewModel.rawAppCount(from: newSelection)
            print("[AppBlockingPopupView] Selection changed on simulator: \(catCount) categories, \(appCount) apps")
            print("  .categories count: \(newSelection.categories.count)")
            print("  .applications count: \(newSelection.applications.count)")
            print("  .categoryTokens count: \(newSelection.categoryTokens.count)")
            print("  .applicationTokens count: \(newSelection.applicationTokens.count)")
            #endif
        }
        .onChange(of: viewModel.draftFromDate) { _, newFrom in
            // Enforce ending time cannot precede starting time
            if viewModel.draftToDate <= newFrom {
                viewModel.draftToDate = newFrom.addingTimeInterval(45 * 60)
            }
        }
        .onChange(of: viewModel.draftToDate) { _, newTo in
            // Enforce ending time cannot precede starting time
            if newTo <= viewModel.draftFromDate {
                viewModel.draftToDate = viewModel.draftFromDate.addingTimeInterval(45 * 60)
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            // Dismiss button
            Button {
                viewModel.showPopup = false
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 38, height: 38)
                        .glassEffect(.clear, in: .circle)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
                        )
                    Image(systemName: "xmark")
                        .font(Typography.subheadline(weight: .bold))
                        .foregroundStyle(.white.opacity(0.88))
                }
            }
            .buttonStyle(.plain)

            Spacer()

            // Block Name
            Text(viewModel.draftName)
                .font(Typography.headline())
                .foregroundStyle(.white)

            Spacer()

            // Balances the close button on the leading side
            Color.clear
                .frame(width: 38, height: 38)
        }
    }

    // MARK: - Sticky Bottom Bar

    private var stickyBottomBar: some View {
        VStack(spacing: 0) {
            // Subtle gradient scrim fading upwards
            LinearGradient(
                colors: [
                    Color.clear,
                    Palette.inkTop.opacity(0.85),
                    Palette.inkBottom.opacity(0.98)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 24)
            .allowsHitTesting(false)

            // Hold to Commit / Save button container
            VStack(spacing: 8) {
                let buttonTitle = viewModel.isEditing ? "Hold to Save" : "Hold to Commit"

                HoldToCommitButton(title: buttonTitle) {
                    triggerCommitWithAnimation()
                }
                .shadow(color: Palette.ember.opacity(0.35), radius: 18, x: 0, y: 6)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 16)
            .background {
                Palette.inkBottom
                    .opacity(0.4)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
    }

    // MARK: - Section 1: During this time

    private func toggleFromPicker() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            activeTimePicker = (activeTimePicker == .from) ? .none : .from
        }
    }

    private func toggleToPicker() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            activeTimePicker = (activeTimePicker == .to) ? .none : .to
        }
    }

    private var duringThisTimeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("During this time:")
                .font(Typography.subheadline())
                .foregroundStyle(.white.opacity(0.7))
                .padding(.leading, 4)

            VStack(spacing: 0) {
                // FROM ROW
                HStack {
                    Text("From")
                        .font(Typography.body())
                        .foregroundStyle(.white)

                    Spacer()

                    // Time display button (clickable)
                    Button(action: toggleFromPicker) {
                        Text(viewModel.draftFromFormatted)
                            .font(Typography.body(weight: .medium))
                            .foregroundStyle(activeTimePicker == .from ? Palette.amber : .white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(activeTimePicker == .from ? Palette.amber.opacity(0.18) : Color.white.opacity(0.06))
                                    .glassEffect(.clear, in: .capsule)
                            )
                    }
                    .buttonStyle(.plain)

                    // Upward/Downward Arrow Button
                    Button(action: toggleFromPicker) {
                        Image(systemName: activeTimePicker == .from ? "chevron.up" : "chevron.down")
                            .font(Typography.footnote(weight: .semibold))
                            .foregroundStyle(activeTimePicker == .from ? Palette.amber : .white.opacity(0.6))
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(activeTimePicker == .from ? Palette.amber.opacity(0.16) : Color.white.opacity(0.06))
                                    .glassEffect(.clear, in: .circle)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Toggle start time picker")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                // Inline From DatePicker
                if activeTimePicker == .from {
                    VStack(spacing: 8) {
                        DatePicker(
                            "",
                            selection: $viewModel.draftFromDate,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .colorScheme(.dark)
                        .frame(height: 150)
                        .clipped()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Divider()
                    .background(Color.white.opacity(0.10))
                    .padding(.horizontal, 16)

                // TO ROW
                HStack {
                    Text("To")
                        .font(Typography.body())
                        .foregroundStyle(.white)

                    Spacer()

                    // Time display button (clickable)
                    Button(action: toggleToPicker) {
                        Text(viewModel.draftToFormatted)
                            .font(Typography.body(weight: .medium))
                            .foregroundStyle(activeTimePicker == .to ? Palette.amber : .white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(activeTimePicker == .to ? Palette.amber.opacity(0.18) : Color.white.opacity(0.06))
                                    .glassEffect(.clear, in: .capsule)
                            )
                    }
                    .buttonStyle(.plain)

                    // Upward/Downward Arrow Button
                    Button(action: toggleToPicker) {
                        Image(systemName: activeTimePicker == .to ? "chevron.up" : "chevron.down")
                            .font(Typography.footnote(weight: .semibold))
                            .foregroundStyle(activeTimePicker == .to ? Palette.amber : .white.opacity(0.6))
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(activeTimePicker == .to ? Palette.amber.opacity(0.16) : Color.white.opacity(0.06))
                                    .glassEffect(.clear, in: .circle)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Toggle end time picker")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                // Inline To DatePicker
                if activeTimePicker == .to {
                    VStack(spacing: 8) {
                        DatePicker(
                            "",
                            selection: $viewModel.draftToDate,
                            in: viewModel.draftFromDate.addingTimeInterval(60)...,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .colorScheme(.dark)
                        .frame(height: 150)
                        .clipped()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            }
            .glassEffect(.clear, in: .rect)
            .cornerRadius(16)
        }
    }

    // MARK: - Section 2: On these days

    private var onTheseDaysSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("On these days:")
                    .font(Typography.subheadline())
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()

                Text(viewModel.selectedDaysSummary)
                    .font(Typography.subheadline(weight: .medium))
                    .foregroundStyle(Palette.amber)
            }
            .padding(.leading, 4)

            HStack(spacing: 0) {
                ForEach([Weekday.sun, .mon, .tue, .wed, .thu, .fri, .sat], id: \.self) { day in
                    let isSelected = viewModel.draftDays.contains(day)

                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            viewModel.toggleDay(day)
                        }
                    } label: {
                        ZStack {
                            if isSelected {
                                Circle()
                                    .fill(Palette.warmGradient)
                                    .glassEffect(.clear, in: .circle)
                                    .frame(width: 38, height: 38)
                                    .shadow(color: Palette.ember.opacity(0.45), radius: 6)
                                Text(day.symbol)
                                    .font(Typography.callout(weight: .bold))
                                    .foregroundStyle(Color.black)
                            } else {
                                Circle()
                                    .fill(Color.white.opacity(0.05))
                                    .frame(width: 38, height: 38)
                                    .glassEffect(.clear, in: .circle)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.24), lineWidth: 1)
                                    )
                                Text(day.symbol)
                                    .font(Typography.callout(weight: .medium))
                                    .foregroundStyle(.white.opacity(0.75))
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    if day != .sat {
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Section 3: Apps are blocked

    private var appsAreBlockedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .font(Typography.subheadline())
                    .foregroundStyle(Palette.amber)
                Text("Apps are blocked")
                    .font(Typography.subheadline())
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.leading, 4)

            // Selector Button Row
            Button {
                viewModel.showAppPicker = true
            } label: {
                HStack {
                    Text("Selected Apps & Categories")
                        .font(Typography.body())
                        .foregroundStyle(.white)

                    Spacer()

                    Text(viewModel.draftSelectionSummary)
                        .font(Typography.callout(weight: .medium))
                        .foregroundStyle(viewModel.selectedAppsCount == 0 ? Color.white.opacity(0.5) : Palette.amber)

                    Image(systemName: "chevron.right")
                        .font(Typography.subheadline(weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.45))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                }
                .glassEffect(.clear, in: .rect)
                .cornerRadius(16)
            }
            .buttonStyle(.plain)

            // Selected Categories & Apps Display Area (So person can see what they have selected)
            if viewModel.draftHasSelection {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .font(Typography.footnote(weight: .semibold))
                            .foregroundStyle(Palette.amber)
                        Text("Active in this block")
                            .font(Typography.footnote(weight: .semibold))
                            .foregroundStyle(.white.opacity(0.85))

                        Spacer()

                        Text("\(viewModel.selectedAppsCount) Selected")
                            .font(Typography.caption(weight: .bold))
                            .foregroundStyle(Palette.amber)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Palette.amber.opacity(0.14)))
                    }

                    // Categories Grid / Chips
                    if !viewModel.draftCategoryItems.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Categories")
                                .font(Typography.caption(weight: .medium))
                                .foregroundStyle(.white.opacity(0.5))
                                .padding(.leading, 2)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
                                ForEach(viewModel.draftCategoryItems) { cat in
                                    HStack(spacing: 8) {
                                        ZStack {
                                            Circle()
                                                .fill(Palette.warmGradient)
                                                .frame(width: 28, height: 28)
                                                .shadow(color: Palette.ember.opacity(0.4), radius: 4)

                                            if let token = cat.token {
                                                Label(token)
                                                    .labelStyle(.iconOnly)
                                                    .font(Typography.footnote())
                                                    .foregroundStyle(Color.black)
                                            } else {
                                                Image(systemName: cat.iconSymbol)
                                                    .font(Typography.footnote(weight: .bold))
                                                    .foregroundStyle(Color.black)
                                            }
                                        }

                                        if let token = cat.token {
                                            Label(token)
                                                .labelStyle(.titleOnly)
                                                .font(Typography.footnote(weight: .semibold))
                                                .foregroundStyle(.white)
                                                .lineLimit(1)
                                        } else {
                                            Text(cat.name)
                                                .font(Typography.footnote(weight: .semibold))
                                                .foregroundStyle(.white)
                                                .lineLimit(1)
                                        }

                                        Spacer(minLength: 0)

                                        Image(systemName: "checkmark")
                                            .font(Typography.caption2(weight: .bold))
                                            .foregroundStyle(Palette.amber)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.06))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Palette.amber.opacity(0.25), lineWidth: 0.8)
                                            )
                                    )
                                }
                            }
                        }
                    }

                    // Specific Apps Grid / Chips (if any)
                    if !viewModel.draftAppItems.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Specific Apps")
                                .font(Typography.caption(weight: .medium))
                                .foregroundStyle(.white.opacity(0.5))
                                .padding(.leading, 2)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(viewModel.draftAppItems) { app in
                                        HStack(spacing: 6) {
                                            if let token = app.token {
                                                Label(token)
                                                    .labelStyle(.iconOnly)
                                                    .frame(width: 22, height: 22)
                                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                            } else {
                                                Image(systemName: "app.fill")
                                                    .font(Typography.caption())
                                                    .foregroundStyle(Palette.amber)
                                            }

                                            Text(app.name)
                                                .font(Typography.caption(weight: .medium))
                                                .foregroundStyle(.white.opacity(0.9))
                                                .lineLimit(1)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(Color.white.opacity(0.06))
                                                .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 0.8))
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
                .id(viewModel.lastUpdated) // Force re-render when selection changes
                .padding(14)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Palette.amber.opacity(0.22), lineWidth: 1)
                        )
                }
                .glassEffect(.clear, in: .rect)
                .cornerRadius(16)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
    }

    // MARK: - Section 4: Hard Mode

    private var hardModeSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Hard Mode")
                        .font(Typography.headline())
                        .foregroundStyle(.white)

                    Text("PRO")
                        .font(Typography.caption2(weight: .bold))
                        .foregroundStyle(Color.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Palette.warmGradient))
                }

                Text("No unblocks allowed")
                    .font(Typography.footnote())
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Toggle("", isOn: $viewModel.draftHardMode)
                .tint(Palette.amber)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        }
        .glassEffect(.clear, in: .rect)
        .cornerRadius(16)
    }

    // MARK: - Commit & Completion Animation Trigger

    private func triggerCommitWithAnimation() {
        isFirstSetup = !viewModel.isEditing
        viewModel.commitDraft(dismissImmediately: false)

        withAnimation(.easeInOut(duration: 0.15)) {
            isShowingCompletionOverlay = true
        }

        withAnimation(.spring(response: 0.72, dampingFraction: 0.76)) {
            checkmarkAnimatedIn = true
        }

        Task {
            try? await Task.sleep(for: .seconds(2.0))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.25)) {
                    isShowingCompletionOverlay = false
                }
                viewModel.showPopup = false
                dismiss()
            }
        }
    }

    // MARK: - Completion Overlay View

    private var completionOverlayView: some View {
        GeometryReader { geo in
            let screenWidth = geo.size.width
            let screenHeight = geo.size.height
            let initialSize = screenWidth * 1.5
            let targetSize = screenWidth * 0.5

            ZStack {
                Color.black.opacity(0.92)
                    .glassEffect(.clear, in: .rect)
                    .ignoresSafeArea()

                VStack(spacing: 22) {
                    ZStack {
                        if isFirstSetup {
                        
                            Image(systemName: "checkmark")
                                .resizable()
                                .scaledToFit()
                                .fontWeight(.bold)
                                .foregroundStyle(Palette.warmGradient)
                                .shadow(color: Palette.ember.opacity(0.50), radius: 16, x: 0, y: 0)
                        } else {
                            Image(systemName: "checkmark")
                                .resizable()
                                .scaledToFit()
                                .fontWeight(.bold)
                                .foregroundStyle(Palette.warmGradient)
                                .shadow(color: Palette.ember.opacity(0.50), radius: 16, x: 0, y: 0)
                        }
                    }
                    .frame(
                        width: checkmarkAnimatedIn ? targetSize : initialSize,
                        height: checkmarkAnimatedIn ? targetSize : initialSize
                    )

                    if isFirstSetup {
                        Text("Setup Complete")
                            .font(Typography.title2(weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: Palette.ember.opacity(0.95), radius: 18, x: 0, y: 0)
                            .shadow(color: Palette.blobGlow.opacity(0.50), radius: 36, x: 0, y: 0)
                            .opacity(checkmarkAnimatedIn ? 1.0 : 0.0)
                            .scaleEffect(checkmarkAnimatedIn ? 1.0 : 0.75)
                    } else {
                        Text("App Block Updated")
                            .font(Typography.title3(weight: .semibold))
                            .foregroundStyle(.white)
                            .opacity(checkmarkAnimatedIn ? 1.0 : 0.0)
                            .scaleEffect(checkmarkAnimatedIn ? 1.0 : 0.8)
                    }
                }
                .position(
                    x: screenWidth / 2,
                    y: checkmarkAnimatedIn ? (screenHeight / 2 - 20) : (screenHeight + initialSize / 2)
                )
            }
            .ignoresSafeArea()
        }
    }
}

#Preview("Sheet Direct - New Block") {
    let vm = AppBlockingViewModel()
    AppBlockingPopupView(viewModel: vm)
}

#Preview("Sheet Direct - Edit Block") {
    let vm = AppBlockingViewModel()
    let _ = vm.openEditBlock(ScheduledBlock.defaultBlock)
    AppBlockingPopupView(viewModel: vm)
}
