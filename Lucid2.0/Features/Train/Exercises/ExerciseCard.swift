//
//  ExerciseCard.swift
//  Lucid2.0
//
//  Horizontal-scroll card for a single exercise.
//  Shows: dynamic multi-SF-symbol glowing artwork, title, subtitle, duration pill.
//

import SwiftUI

public struct ExerciseCard: View {
    public let exercise: ExerciseDefinition
    public let isRecommended: Bool
    public let onTap: () -> Void
    public let onInfo: () -> Void

    public init(
        exercise: ExerciseDefinition,
        isRecommended: Bool = false,
        onTap: @escaping () -> Void,
        onInfo: @escaping () -> Void
    ) {
        self.exercise = exercise
        self.isRecommended = isRecommended
        self.onTap = onTap
        self.onInfo = onInfo
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 0) {
                    // MARK: - Thumbnail with Glowing SF Symbol Artwork
                    ZStack(alignment: .topTrailing) {
                        ExerciseArtworkView(exercise: exercise, style: .card)
                            .frame(width: cardWidth, height: cardWidth)
                            .clipped()
                            .overlay(alignment: .bottom) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Spacer().frame(height: 50)
                                    Text(exercise.title)
                                        .font(Typography.subheadline(weight: .semibold))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)

                                    // Duration pill
                                    HStack(spacing: 3) {
                                        Image(systemName: "clock")
                                            .font(Typography.caption2())
                                        Text(exercise.durationMinutesFormatted)
                                            .font(Typography.caption2(weight: .medium))
                                    }
                                    .foregroundStyle(Palette.amber)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(Palette.amber.opacity(0.12))
                                            .overlay(Capsule().strokeBorder(Palette.amber.opacity(0.25), lineWidth: 0.7))
                                    )
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .frame(width: cardWidth, alignment: .leading)
                                .background {
                                    LinearGradient(
                                        colors: [.clear, Palette.cardBottom.opacity(0.95)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                }
                            }
                    }
                    .cornerRadius(24)
                }
                .frame(width: cardWidth)
                .cardBackground(top: Palette.cardTop, bottom: Palette.cardBottom, corner: 18)
                .overlay {
                    if isRecommended {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Palette.amber.opacity(0.35),
                                        Palette.amber.opacity(0.12)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .background {
                    if isRecommended {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Palette.amber.opacity(0.18),
                                        Palette.ember.opacity(0.06)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .blur(radius: 10)
                    }
                }
                .shadow(color: isRecommended ? Palette.amber.opacity(0.18) : .clear, radius: 8, x: 0, y: 2)
                .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)

            // Info affordance — opens the detail sheet without starting the exercise
            Button(action: onInfo) {
                Image(systemName: "info.circle.fill")
                    .font(Typography.caption(weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(6)
                    .background(Circle().fill(Color.black.opacity(0.4)))
            }
            .buttonStyle(.plain)
            .padding(10)
        }
        .frame(width: cardWidth)
    }

    private var cardWidth: CGFloat { 160 }
}

// MARK: - Recommended Exercise Card (wider, full-width)

public struct RecommendedExerciseCard: View {
    public let exercise: ExerciseDefinition
    public let onTap: () -> Void
    public let onInfo: () -> Void

    public init(exercise: ExerciseDefinition, onTap: @escaping () -> Void, onInfo: @escaping () -> Void) {
        self.exercise = exercise
        self.onTap = onTap
        self.onInfo = onInfo
    }

    public var body: some View {
        ZStack(alignment: .trailing) {
            Button(action: onTap) {
                HStack(spacing: 0) {
                    // Left: Dynamic SF Symbol artwork panel
                    Color.clear
                        .frame(width: 110, height: 110)
                        .overlay {
                            ZStack(alignment: .trailing) {
                                ExerciseArtworkView(exercise: exercise, style: .banner)
                                    .frame(width: 110, height: 110)

                                // Side fade into card body
                                LinearGradient(
                                    colors: [.clear, Palette.cardTop],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(width: 32)
                            }
                        }
                        .clipped()

                    // Right: Text info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 5) {
                            Image(systemName: "star.fill")
                                .font(Typography.caption2(weight: .bold))
                                .foregroundStyle(Palette.amber)
                            Text("Recommended")
                                .font(Typography.caption2(weight: .semibold))
                                .foregroundStyle(Palette.amber)
                        }

                        Text(exercise.title)
                            .font(Typography.subheadline(weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        Text(exercise.recommendationReason)
                            .font(Typography.caption())
                            .foregroundStyle(Color.white.opacity(0.6))
                            .lineLimit(2)

                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(Typography.caption2())
                            Text(exercise.durationMinutesFormatted)
                                .font(Typography.caption2(weight: .medium))
                        }
                        .foregroundStyle(Palette.amber)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(
                            Capsule()
                                .fill(Palette.amber.opacity(0.12))
                                .overlay(Capsule().strokeBorder(Palette.amber.opacity(0.25), lineWidth: 0.7))
                        )
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)

                    Spacer(minLength: 0)

                    // Reserve space so the row text doesn't sit under the info button
                    Color.clear.frame(width: 36)
                }
                .frame(height: 110)
                .frame(maxWidth: .infinity)
                .cardBackground(top: Palette.cardTop, bottom: Palette.cardBottom, corner: 18)
                .overlay(
                    // Subtle warm ambient glow inside the card background
                    RadialGradient(
                        colors: [
                            Palette.amber.opacity(0.12),
                            Palette.ember.opacity(0.04),
                            Color.clear
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 200
                    )
                    .allowsHitTesting(false)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Palette.amber.opacity(0.35),
                                    Palette.amber.opacity(0.15),
                                    Palette.amber.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .background(
                    // Soft ambient glow in the background of the recommended exercise card
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Palette.amber.opacity(0.20),
                                    Palette.ember.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blur(radius: 12)
                )
                .shadow(color: Palette.amber.opacity(0.18), radius: 10, x: 0, y: 3)
                .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)

            // Info affordance — opens the detail sheet without starting the exercise
            Button(action: onInfo) {
                Image(systemName: "info.circle.fill")
                    .font(Typography.title3(weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.4))
            }
            .buttonStyle(.plain)
            .padding(.trailing, 14)
        }
    }
}

// MARK: - Today Hero Card (full-width Apple-Music-style featured card)

public struct TodayHeroCard: View {
    public let exercise: ExerciseDefinition
    public let onStart: () -> Void
    public let onInfo: () -> Void

    public init(exercise: ExerciseDefinition, onStart: @escaping () -> Void, onInfo: @escaping () -> Void) {
        self.exercise = exercise
        self.onStart = onStart
        self.onInfo = onInfo
    }

    private var cardHeight: CGFloat { 270 }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onStart) {
                ZStack(alignment: .bottomLeading) {
                    ExerciseArtworkView(exercise: exercise, style: .hero)
                        .frame(height: cardHeight)
                        .frame(maxWidth: .infinity)
                        .clipped()

                    LinearGradient(
                        colors: [.clear, .clear, Palette.cardBottom.opacity(0.98)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: cardHeight)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 5) {
                            Image(systemName: "sparkles")
                                .font(Typography.caption2(weight: .bold))
                            Text("Today's Focus")
                                .font(Typography.caption2(weight: .bold))
                        }
                        .foregroundStyle(Palette.amber)

                        Text(exercise.title)
                            .font(Typography.largeTitle(weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        Text(exercise.recommendationReason)
                            .font(Typography.subheadline())
                            .foregroundStyle(Color.white.opacity(0.7))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 10) {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                Text(exercise.durationMinutesFormatted)
                            }
                            .font(Typography.caption(weight: .medium))
                            .foregroundStyle(Palette.amber)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Palette.amber.opacity(0.14)))

                            HStack(spacing: 6) {
                                Image(systemName: "play.fill")
                                Text("Start")
                            }
                            .font(Typography.subheadline(weight: .bold, design: .rounded))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Palette.amber))
                        }
                        .padding(.top, 2)
                    }
                    .padding(18)
                }
                .frame(height: cardHeight)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            }
            .buttonStyle(.plain)

            // Info affordance — opens the detail sheet without starting the exercise
            Button(action: onInfo) {
                Image(systemName: "info.circle.fill")
                    .font(Typography.subheadline(weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(8)
                    .background(Circle().fill(Color.black.opacity(0.35)))
            }
            .buttonStyle(.plain)
            .padding(14)
        }
        .shadow(color: Palette.amber.opacity(0.2), radius: 14, x: 0, y: 6)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 20) {
            TodayHeroCard(exercise: .smoothPursuits, onStart: {}, onInfo: {})
            ExerciseCard(exercise: .smoothPursuits, onTap: {}, onInfo: {})
            RecommendedExerciseCard(exercise: .blinkTraining, onTap: {}, onInfo: {})
        }
        .padding()
    }
}
