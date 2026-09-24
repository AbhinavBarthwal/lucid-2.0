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

    public init(
        exercise: ExerciseDefinition,
        isRecommended: Bool = false,
        onTap: @escaping () -> Void
    ) {
        self.exercise = exercise
        self.isRecommended = isRecommended
        self.onTap = onTap
    }

    public var body: some View {
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

                                HStack(spacing: 6) {
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

                                    Spacer(minLength: 0)

                                    // Info indicator
                                    Image(systemName: "info.circle.fill")
                                        .font(Typography.caption())
                                        .foregroundStyle(Color.white.opacity(0.35))
                                }
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
    }

    private var cardWidth: CGFloat { 160 }
}

// MARK: - Recommended Exercise Card (wider, full-width)

public struct RecommendedExerciseCard: View {
    public let exercise: ExerciseDefinition
    public let onTap: () -> Void

    public init(exercise: ExerciseDefinition, onTap: @escaping () -> Void) {
        self.exercise = exercise
        self.onTap = onTap
    }

    public var body: some View {
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

                // Chevron
                Image(systemName: "chevron.right")
                    .font(Typography.caption(weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.3))
                    .padding(.trailing, 14)
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
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 20) {
            ExerciseCard(exercise: .smoothPursuits, onTap: {})
            RecommendedExerciseCard(exercise: .blinkTraining, onTap: {})
        }
        .padding()
    }
}
