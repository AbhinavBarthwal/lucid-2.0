//
//  ScoreHeroView.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import SwiftUI

public struct ScoreHeroView: View {
    @State private var floating = false
    @State private var scoreEngine = LucidScoreEngine.shared
    @ScaledMetric(relativeTo: .largeTitle) private var scoreFontSize: CGFloat = 46
    private let characterImage = "Luc"

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Warm glow behind Luc
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Palette.blobGlow.opacity(0.42), Palette.blobGlow.opacity(0)],
                            center: .center,
                            startRadius: 6,
                            endRadius: 165
                        )
                    )
                    .frame(width: 330, height: 330)
                    .scaleEffect(floating ? 1.06 : 0.94)

                Image(characterImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .shadow(color: Palette.blobGlow.opacity(0.45), radius: 22, y: 10)
                    .offset(y: floating ? -6 : 6)
                    .rotationEffect(.degrees(floating ? 2.5 : -2.5))
            }
            .frame(width: 200, height: 200)
            .padding(.top, 125)
            .animation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true), value: floating)
            .onAppear { floating = true }

            // Score Display: Calibrated (Real Score) vs Uncalibrated (Blurred Glass)
            VStack(spacing: 6) {
                if let score = scoreEngine.calibratedOverallScore {
                    // Calibrated Score
                    Text("\(score)")
                        .font(Typography.hero(size: scoreFontSize, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())

                    Text("Total Score")
                        .font(Typography.subheadline(weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.6))
                } else {
                    // Uncalibrated / Blurred Glass State
                    ZStack {
                        // Blurred score silhouette
                        Text("72")
                            .font(Typography.hero(size: scoreFontSize, weight: .bold, design: .rounded))
                            .foregroundStyle(Palette.amber.opacity(0.4))
                            .blur(radius: 12)

                        // Glass Badge with Lock/Calibration Sparkle
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(Typography.footnote(weight: .bold))
                                .foregroundStyle(Palette.warmGradient)
                            Text("Calibrating")
                                .font(Typography.subheadline(weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().strokeBorder(Palette.amber.opacity(0.45), lineWidth: 1.2)
                        )
                        .shadow(color: Palette.ember.opacity(0.3), radius: 10, y: 4)
                    }
                    .frame(height: 54)

                    // Calibration Status Pill
                    HStack(spacing: 6) {
                        Image(systemName: "gauge.with.needle")
                            .font(Typography.caption2(weight: .medium))
                            .foregroundStyle(Palette.amber)

                        Text("Day 1 Calibration: \(scoreEngine.calibrationTasksCompleted)/2 complete")
                            .font(Typography.caption(weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.75))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8)
                    )
                    .padding(.top, 2)
                }
            }
            .padding(.top, 20)
            .animation(.spring(response: 0.5, dampingFraction: 0.82), value: scoreEngine.isScoreCalibrated)

            ConnectorShape()
                .stroke(Color.white.opacity(0.2),
                        style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                .frame(width: 212, height: 18)
                .padding(.top, 12)

            HStack(spacing: 32) {
                ScoreChip(icon: "dumbbell.fill", title: "Exercise", value: scoreEngine.calibratedExerciseScore)
                ScoreChip(icon: "list.clipboard", title: "Tests", value: scoreEngine.calibratedTestScore)
                ScoreChip(icon: "tree.fill", title: "Rest", value: scoreEngine.calibratedRestScore)
            }
            .padding(.top, 18)
        }
        .frame(maxWidth: .infinity)
    }
}

public struct ScoreChip: View {
    public let icon: String
    public let title: String
    public let value: Int?

    public init(icon: String, title: String, value: Int? = nil) {
        self.icon = icon
        self.title = title
        self.value = value
    }

    public var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Capsule().fill(Color.black.opacity(0.28))
                Capsule()
                    .strokeBorder(
                        Color.white.opacity(0.18),
                        style: StrokeStyle(lineWidth: 1.6, dash: [5, 3.5])
                    )
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(Typography.subheadline())
                        .foregroundStyle(Color.white.opacity(0.75))

                    if let scoreValue = value {
                        Text("\(scoreValue)")
                            .font(Typography.footnote(weight: .bold, design: .rounded))
                            .foregroundStyle(Palette.amber)
                    } else {
                        // Blurred placeholder while the score is "analyzing / calibrating"
                        Capsule()
                            .fill(Color(white: 0.55).opacity(0.4))
                            .frame(width: 22, height: 14)
                            .blur(radius: 4)
                    }
                }
            }
            .frame(minWidth: 74, minHeight: 42)

            Text(title)
                .font(Typography.callout(weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.6))
        }
    }
}
