//
//  StreakCard.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import SwiftUI

public struct StreakCard: View {
    public var count: Int?
    @State private var streakManager = StreakManager.shared
    @State private var showDetailSheet = false

    public init(count: Int? = nil) {
        self.count = count
    }

    private var effectiveCount: Int {
        count ?? streakManager.currentStreak
    }

    public var body: some View {
        Button {
            showDetailSheet = true
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(effectiveCount > 0 ? "\(effectiveCount) Day Streak!" : "Start Your Streak!")
                            .font(Typography.headline())
                            .foregroundStyle(.white)

                        Text(subtitleText)
                            .font(Typography.subheadline())
                            .foregroundStyle(Color.white.opacity(0.65))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    FlameBadge(count: effectiveCount)
                }

                // Interactive info & share pill
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(Typography.caption2(weight: .semibold))
                        .foregroundStyle(Palette.amber)

                    Text("How it's calculated & shared")
                        .font(Typography.caption(weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.8))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(Typography.caption2(weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.45))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.8)
                        )
                )
            }
            .padding(.leading, 20)
            .padding(.trailing, 18)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [Palette.ember.opacity(0.26), Palette.ember.opacity(0)],
                            center: .bottomTrailing,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
            )
            .cardBackground(
                top: Color(red: 0.12, green: 0.16, blue: 0.28),
                bottom: Color(red: 0.05, green: 0.07, blue: 0.13)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetailSheet) {
            StreakDetailSheet()
                .presentationDetents([.fraction(0.85), .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var subtitleText: String {
        if effectiveCount == 0 {
            return "Complete 1 eye exercise today to ignite your daily vision streak."
        } else if streakManager.isCompletedToday {
            return "Streak safe! You've completed your daily training for today."
        } else {
            return "Complete 1 exercise before midnight to extend your streak to \(effectiveCount + 1) days!"
        }
    }
}

public struct FlameBadge: View {
    public let count: Int
    @ScaledMetric(relativeTo: .largeTitle) private var flameSize: CGFloat = 82
    @ScaledMetric(relativeTo: .largeTitle) private var countFontSize: CGFloat = 40

    public init(count: Int = 0) {
        self.count = count
    }

    public var body: some View {
        ZStack {
            Image(systemName: "flame.fill")
                .font(Typography.hero(size: flameSize, relativeTo: .largeTitle))
                .foregroundStyle(
                    LinearGradient(
                        colors: count > 0 ? [
                            Color.white,
                            Color(red: 1.0, green: 0.86, blue: 0.45).opacity(0.75),
                            Color(red: 0.55, green: 0.42, blue: 0.10).opacity(0.55)
                        ] : [
                            Color.white.opacity(0.4),
                            Color.gray.opacity(0.3),
                            Color.black.opacity(0.2)
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .shadow(color: count > 0 ? Palette.ember.opacity(0.7) : Color.clear, radius: 12, y: -4)

            Text("\(count)")
                .font(Typography.hero(size: countFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(count > 0 ? Color(red: 0.98, green: 0.82, blue: 0.20) : Color.white.opacity(0.5))
                .offset(y: 14)
        }
        .frame(minWidth: 64, minHeight: 92)
    }
}
