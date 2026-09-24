//
//  StreakCard.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import SwiftUI

public struct StreakCard: View {
    public var count: Int = 0

    public init(count: Int = 0) {
        self.count = count
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(count > 0 ? "\(count) Day Streak!" : "You lost your streak")
                    .font(Typography.headline())
                    .foregroundStyle(.white)
                Text(count > 0 ? "Keep your momentum going and protect your eyes today." : "Don't worry, losing is a part of the journey. Just start again.")
                    .font(Typography.subheadline())
                    .foregroundStyle(Color.white.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            FlameBadge(count: count)
        }
        .padding(.leading, 20)
        .padding(.trailing, 18)
        .padding(.vertical, 20)
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
        .cardBackground(top: Color(red: 0.12, green: 0.16, blue: 0.28),
                        bottom: Color(red: 0.05, green: 0.07, blue: 0.13))
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
                        colors: [Color.white,
                                 Color(red: 1.0, green: 0.86, blue: 0.45).opacity(0.75),
                                 Color(red: 0.55, green: 0.42, blue: 0.10).opacity(0.55)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .shadow(color: Palette.ember.opacity(0.7), radius: 12, y: -4)

            Text("\(count)")
                .font(Typography.hero(size: countFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.98, green: 0.82, blue: 0.20))
                .offset(y: 14)
        }
        .frame(minWidth: 64, minHeight: 92)
    }
}
