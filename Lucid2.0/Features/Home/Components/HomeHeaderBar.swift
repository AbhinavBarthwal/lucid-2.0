//
//  HomeHeaderBar.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import SwiftUI

public struct HomeHeaderBar: View {
    public var streakCount: Int = 0
    public var onProfileTapped: (() -> Void)? = nil

    public init(streakCount: Int = 0, onProfileTapped: (() -> Void)? = nil) {
        self.streakCount = streakCount
        self.onProfileTapped = onProfileTapped
    }

    public var body: some View {
        HStack(spacing: 0) {
            Text("Lucid")
                .font(Typography.largeTitle(weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "drop.fill")
                    .font(Typography.title2())
                    .foregroundStyle(Palette.warmGradient)
                Text("\(streakCount)")
                    .font(Typography.title2(weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.5))
            }
            .padding(.trailing, 22)

            Button {
                onProfileTapped?()
            } label: {
                ZStack {
                    Circle()
                        .fill(Palette.amber.opacity(0.12))
                        .glassEffect(.clear, in: .circle)
                        .overlay(
                            Circle()
                                .stroke(Palette.amber.opacity(0.6), lineWidth: 1.5)
                        )
                    Image(systemName: "person.fill")
                        .font(Typography.headline())
                        .foregroundStyle(Palette.warmGradient)
                }
                .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 20)
        .padding(.trailing, 30)
        .frame(minHeight: 48)
    }
}
