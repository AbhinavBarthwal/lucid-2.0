//
//  StartTestCard.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import SwiftUI

public struct StartTestCard: View {
    public var onStartTest: () -> Void

    public init(onStartTest: @escaping () -> Void) {
        self.onStartTest = onStartTest
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header Row: Section Label + Time Duration Badge
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "waveform.path.ecg")
                        .font(Typography.footnote(weight: .semibold))
                        .foregroundStyle(Palette.amber)

                    Text("Eye Tests")
                        .font(Typography.headline())
                        .foregroundStyle(.white)
                }

                Spacer()

                // Time duration badge
                HStack(spacing: 5) {
                    Image(systemName: "clock")
                        .font(Typography.caption(weight: .medium))
                        .foregroundStyle(Palette.amber)

                    Text("~4 mins")
                        .font(Typography.footnote(weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.85))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8))
                )
            }

            // Primary Call to Action Button
            Button(action: onStartTest) {
                HStack(spacing: 8) {
                    Text("Start Test")
                        .font(Typography.headline(weight: .bold))
                        .foregroundStyle(Color.black)

                    Image(systemName: "arrow.right")
                        .font(Typography.subheadline(weight: .bold))
                        .foregroundStyle(Color.black)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: 44, style: .continuous)
                        .fill(Palette.warmGradient)
                        .glassEffect(.clear, in: .capsule)
                        .shadow(color: Palette.ember.opacity(0.45), radius: 14, x: 0, y: 5)
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .cardBackground(top: Palette.cardTop, bottom: Palette.cardBottom, corner: 24)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        StartTestCard(onStartTest: {})
            .padding()
    }
}
