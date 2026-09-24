//
//  PersonalizedPlanRevealView.swift
//  Lucid2.0
//
//  Created by Antigravity on 21/09/26.
//

import SwiftUI

public struct PersonalizedPlanRevealView: View {
    public let blueprint: PersonalizedPlanBlueprint
    public let userName: String
    public let onStart: () -> Void

    @State private var floating = false
    @State private var isLoaded = false

    public init(
        blueprint: PersonalizedPlanBlueprint,
        userName: String,
        onStart: @escaping () -> Void
    ) {
        self.blueprint = blueprint
        self.userName = userName
        self.onStart = onStart
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Mascot Hero
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Palette.blobGlow.opacity(0.35), Palette.blobGlow.opacity(0)],
                                center: .center,
                                startRadius: 4,
                                endRadius: 120
                            )
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(floating ? 1.05 : 0.95)

                    Image("Luc")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 130, height: 130)
                        .shadow(color: Palette.blobGlow.opacity(0.4), radius: 18, y: 8)
                        .offset(y: floating ? -5 : 5)
                }
                .frame(height: 140)
                .animation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true), value: floating)
                .onAppear { floating = true }

                // Title & Subtitle
                VStack(spacing: 6) {
                    Text(userName.isEmpty ? "Your Personalized Plan" : "\(userName)'s Eye Care Plan")
                        .font(Typography.title2(weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(blueprint.headline)
                        .font(Typography.subheadline(weight: .medium))
                        .foregroundStyle(Palette.amber)

                    Text(blueprint.subheadline)
                        .font(Typography.footnote())
                        .foregroundStyle(Color.white.opacity(0.6))
                }
                .multilineTextAlignment(.center)

                // 1. Initial Lucid Score Calibration Card
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Starting Lucid Score")
                            .font(Typography.subheadline(weight: .semibold))
                            .foregroundStyle(.white)
                        Text("Calibrated from your screen time and health inputs.")
                            .font(Typography.caption())
                            .foregroundStyle(Color.white.opacity(0.65))
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Text("\(blueprint.startingRestScore)")
                            .font(Typography.hero(size: 32, weight: .bold, design: .rounded, relativeTo: .title))
                            .foregroundStyle(Palette.warmGradient)
                        Text("Rest Score")
                            .font(Typography.caption2(weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.5))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Palette.amber.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(18)
                .cardBackground(top: Palette.cardTop, bottom: Palette.cardBottom, corner: 22)

                // 2. Discrepancy Insight Card (if present)
                if let disc = blueprint.discrepancy {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "chart.xyaxis.line")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Palette.amber)
                            Text("Screen Time Insight")
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(Palette.amber)
                        }

                        Text(disc.message)
                            .font(.subheadline)
                            .foregroundStyle(Color.white.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)

                        Text(disc.recommendationNote)
                            .font(.caption)
                            .foregroundStyle(Color.white.opacity(0.6))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(18)
                    .cardBackground(top: Color(red: 0.14, green: 0.18, blue: 0.30),
                                    bottom: Color(red: 0.06, green: 0.08, blue: 0.15),
                                    corner: 22)
                }

                // 3. Recommended Exercises Stack
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "dumbbell.fill")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Palette.amber)
                        Text("Daily Exercise Focus")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }

                    VStack(spacing: 10) {
                        ForEach(blueprint.recommendedExercises) { exercise in
                            HStack(spacing: 12) {
                                Image(systemName: exercise.systemIcon)
                                    .font(.title3)
                                    .foregroundStyle(Palette.warmGradient)
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(exercise.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white)
                                    Text(exercise.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(Color.white.opacity(0.55))
                                        .lineLimit(1)
                                }

                                Spacer()

                                Text(exercise.durationMinutesFormatted)
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(Palette.amber)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Palette.amber.opacity(0.12)))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                }
                .padding(18)
                .cardBackground(top: Palette.cardTop, bottom: Palette.cardBottom, corner: 22)

                // 4. Suggested App Blocking Target
                HStack(spacing: 14) {
                    Image(systemName: "hourglass.badge.lock")
                        .font(.title2)
                        .foregroundStyle(Palette.warmGradient)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Suggested Shield Window")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text(blueprint.recommendedBlockSlot)
                            .font(.caption)
                            .foregroundStyle(Palette.amber)
                    }

                    Spacer()
                }
                .padding(16)
                .cardBackground(top: Palette.cardTop, bottom: Palette.cardBottom, corner: 20)

                // Primary CTA Button
                Button(action: onStart) {
                    HStack(spacing: 8) {
                        Text("Begin Your Journey")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color.black)

                        Image(systemName: "arrow.right")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.black)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 44, style: .continuous)
                            .fill(Palette.warmGradient)
                            .glassEffect(.clear, in: .capsule)
                            .shadow(color: Palette.ember.opacity(0.45), radius: 14, x: 0, y: 5)
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 10)
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 22)
            .padding(.top, 10)
        }
    }
}
