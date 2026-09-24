//
//  ExerciseShadeTransitionView.swift
//  Lucid2.0
//
//  Animated shade transition that seamlessly bridges the Care page
//  and the exercise session with glowing multi-SF-Symbol artwork.
//

import SwiftUI
import UIKit

public enum ShadeTransitionState {
    /// Shade sweeps down from top to cover the screen
    case closing
    /// Shade is fully covering
    case covered
    /// Shade rolls up / retracts to reveal the exercise view underneath
    case revealing
}

public struct ExerciseShadeTransitionView: View {
    public let exercise: ExerciseDefinition
    public let mode: ShadeTransitionMode
    public var onCovered: (() -> Void)? = nil
    public var onRevealed: (() -> Void)? = nil

    public enum ShadeTransitionMode {
        /// Slide down to cover (used when tapping Start Exercise in sheet)
        case cover
        /// Slide up to reveal (used when entering the exercise session view)
        case reveal
    }

    @State private var shadeOffset: CGFloat = 0
    @State private var edgeGlowOpacity: Double = 1.0
    @State private var statusText: String = "GET READY"
    @State private var countdown: Int = 3
    @State private var isRevealed: Bool = false

    public init(
        exercise: ExerciseDefinition,
        mode: ShadeTransitionMode,
        onCovered: (() -> Void)? = nil,
        onRevealed: (() -> Void)? = nil
    ) {
        self.exercise = exercise
        self.mode = mode
        self.onCovered = onCovered
        self.onRevealed = onRevealed
    }

    public var body: some View {
        GeometryReader { geo in
            let height = geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom + 50

            ZStack(alignment: .bottom) {
                // 1. Dark glass / obsidian curtain
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(red: 0.02, green: 0.03, blue: 0.06),
                            Color(red: 0.04, green: 0.06, blue: 0.12),
                            Color(red: 0.02, green: 0.03, blue: 0.06)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()

                    // Subtle background radial glow
                    RadialGradient(
                        colors: [
                            Palette.amber.opacity(0.18),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 300
                    )
                    .allowsHitTesting(false)

                    // 2. Central Content on the Shade
                    VStack(spacing: 24) {
                        Spacer()

                        // Multi-symbol glowing artwork
                        ExerciseArtworkView(
                            exercise: exercise,
                            style: .fullShade,
                            isLaunching: true
                        )
                        .frame(width: 200, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Palette.amber.opacity(0.4),
                                            Color.white.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: Palette.amber.opacity(0.35), radius: 24)

                        // Title & Status
                        VStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(Typography.caption(weight: .bold))
                                    .foregroundStyle(Palette.amber)

                                Text(mode == .cover ? "STARTING SESSION" : "SESSION ACTIVE")
                                    .font(Typography.caption(weight: .bold))
                                    .kerning(1.2)
                                    .foregroundStyle(Palette.amber)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(Palette.amber.opacity(0.12))
                                    .overlay(Capsule().strokeBorder(Palette.amber.opacity(0.3), lineWidth: 1))
                            )

                            Text(exercise.title)
                                .font(Typography.title2(weight: .bold))
                                .foregroundStyle(.white)

                            Text(exercise.subtitle)
                                .font(Typography.footnote())
                                .foregroundStyle(Color.white.opacity(0.65))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 36)
                        }

                        Spacer()
                    }
                }
                .frame(width: geo.size.width, height: height)

                // 3. Glowing leading neon laser edge at the bottom of the shade
                VStack(spacing: 0) {
                    // Bright neon core
                    LinearGradient(
                        colors: [
                            Palette.amber.opacity(0.2),
                            Palette.amber,
                            Palette.honey,
                            Palette.amber,
                            Palette.amber.opacity(0.2)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 2.5)
                    .shadow(color: Palette.amber, radius: 14, x: 0, y: 0)
                    .shadow(color: Palette.ember, radius: 24, x: 0, y: 2)

                    // Laser beam dispersion haze
                    LinearGradient(
                        colors: [
                            Palette.amber.opacity(0.35),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 18)
                }
                .frame(width: geo.size.width)
                .opacity(edgeGlowOpacity)
            }
            .offset(y: shadeOffset)
            .onAppear {
                runShadeAnimation(totalHeight: height)
            }
        }
        .ignoresSafeArea()
    }

    private func runShadeAnimation(totalHeight: CGFloat) {
        if mode == .cover {
            // Start above screen, sweep down to cover
            shadeOffset = -totalHeight
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()

            withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                shadeOffset = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                onCovered?()
            }
        } else {
            // Mode is .reveal: Start fully covering, then smoothly lift away!
            shadeOffset = 0
            edgeGlowOpacity = 1.0

            // Hold briefly for dramatic transition, then lift up
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()

                withAnimation(.spring(response: 0.72, dampingFraction: 0.85)) {
                    shadeOffset = -totalHeight
                    edgeGlowOpacity = 0.0
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                    isRevealed = true
                    onRevealed?()
                }
            }
        }
    }
}
