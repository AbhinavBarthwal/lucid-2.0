//
//  TestCard.swift
//  Lucid2.0
//
//  Horizontal-scroll card for a single vision test.
//  Matches ExerciseCard style: square SF-symbol artwork thumbnail, gradient overlay, duration pill, and info indicator.
//

import SwiftUI

public struct TestCard: View {
    public let test: TestDefinition
    public let onTap: () -> Void

    public init(test: TestDefinition, onTap: @escaping () -> Void) {
        self.test = test
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // MARK: - Thumbnail with Glowing SF Symbol Artwork
                ZStack(alignment: .topTrailing) {
                    ExerciseArtworkView(test: test, style: .card)
                        .frame(width: cardWidth, height: cardWidth)
                        .clipped()
                        .overlay(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 4) {
                                Spacer().frame(height: 50)
                                Text(test.title)
                                    .font(Typography.subheadline(weight: .semibold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)

                                HStack(spacing: 6) {
                                    // Duration pill
                                    HStack(spacing: 3) {
                                        Image(systemName: "clock")
                                            .font(Typography.caption2())
                                        Text(test.durationFormatted)
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
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var cardWidth: CGFloat { 160 }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        HStack(spacing: 12) {
            TestCard(test: .landoltC, onTap: {})
            TestCard(test: .osdi, onTap: {})
        }
        .padding()
    }
}
