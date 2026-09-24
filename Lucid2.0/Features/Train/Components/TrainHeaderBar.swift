//
//  TrainHeaderBar.swift
//  Lucid2.0
//
//

import SwiftUI

public struct TrainHeaderBar: View {
    public var onProfileTapped: (() -> Void)? = nil

    public init(onProfileTapped: (() -> Void)? = nil) {
        self.onProfileTapped = onProfileTapped
    }

    public var body: some View {
        HStack(spacing: 0) {
            Text("Train")
                .font(Typography.largeTitle(weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

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
