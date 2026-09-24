//
//  TestDetailSheet.swift
//  Lucid2.0
//
//  Bottom sheet shown when a user taps a vision test card.
//

import SwiftUI

public struct TestDetailSheet: View {
    public let test: TestDefinition
    public var onStart: () -> Void
    public var onDismiss: () -> Void

    public init(
        test: TestDefinition,
        onStart: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.test = test
        self.onStart = onStart
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack(alignment: .top) {
            // Background
            Color(red: 0.05, green: 0.06, blue: 0.12).ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Hero Image
                ZStack {
                    Image(test.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipped()

                    LinearGradient(
                        colors: [.clear, Color(red: 0.05, green: 0.06, blue: 0.12)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                    .frame(maxWidth: .infinity, alignment: .bottom)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
                .frame(height: 220)

                // MARK: - Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        // Title + Duration
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(test.title)
                                    .font(Typography.title2(weight: .bold))
                                    .foregroundStyle(.white)
                                Text(test.subtitle)
                                    .font(Typography.subheadline())
                                    .foregroundStyle(Color.white.opacity(0.6))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()

                            VStack(spacing: 3) {
                                Image(systemName: "clock.fill")
                                    .font(Typography.title3())
                                    .foregroundStyle(Palette.amber)
                                Text(test.durationFormatted)
                                    .font(Typography.caption(weight: .semibold))
                                    .foregroundStyle(Palette.amber)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Palette.amber.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .strokeBorder(Palette.amber.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }

                        // Description card
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle.fill")
                                    .font(Typography.footnote())
                                    .foregroundStyle(Palette.amber)
                                Text("About this test")
                                    .font(Typography.footnote(weight: .semibold))
                                    .foregroundStyle(Palette.amber)
                            }
                            Text(test.description)
                                .font(Typography.callout())
                                .foregroundStyle(Color.white.opacity(0.75))
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(3)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Palette.amber.opacity(0.07))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(Palette.amber.opacity(0.2), lineWidth: 1)
                                )
                        )

                        // How the score is used
                        HStack(spacing: 8) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(Typography.caption(weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.55))
                            Text("Your result contributes to your overall Lucid Score")
                                .font(Typography.caption())
                                .foregroundStyle(Color.white.opacity(0.5))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.white.opacity(0.04))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )

                        // MARK: - CTA Button
                        Button(action: {
                            onStart()
                        }) {
                            HStack(spacing: 8) {
                                Text("Start Test")
                                    .font(Typography.headline(weight: .bold))
                                    .foregroundStyle(Color.black)
                                Image(systemName: "arrow.right")
                                    .font(Typography.subheadline(weight: .bold))
                                    .foregroundStyle(Color.black)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 44, style: .continuous)
                                    .fill(Palette.warmGradient)
                                    .glassEffect(.clear, in: .capsule)
                                    .shadow(color: Palette.ember.opacity(0.4), radius: 14, x: 0, y: 6)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 18)
                    .padding(.bottom, 48)
                }
            }

            // Drag handle
            Capsule()
                .fill(Color.white.opacity(0.2))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
        }
    }
}

#Preview {
    TestDetailSheet(test: .landoltC, onStart: {}, onDismiss: {})
}
