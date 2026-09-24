//
//  TestDetailSheet.swift
//  Lucid2.0
//
//  Half/medium presentation sheet showing details for a selected vision test.
//  Uses dynamic SF-symbol artwork instead of photos.
//

import SwiftUI

public struct TestDetailSheet: View {
    public let test: TestDefinition
    public let onStart: () -> Void
    public let onDismiss: () -> Void

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
                // MARK: - Hero Artwork
                ZStack {
                    ExerciseArtworkView(test: test, style: .hero)
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

                        // Target Area Badges
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TARGET METRIC")
                                .font(Typography.caption2(weight: .bold))
                                .foregroundStyle(Palette.amber)
                                .kerning(1.2)

                            HStack(spacing: 8) {
                                HStack(spacing: 4) {
                                    Image(systemName: test.systemIcon)
                                        .font(Typography.caption2())
                                    Text(test.title)
                                        .font(Typography.caption2(weight: .medium))
                                }
                                .foregroundStyle(.white.opacity(0.85))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.08))
                                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8))
                                )
                            }
                        }

                        // Clinical Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CLINICAL OVERVIEW")
                                .font(Typography.caption2(weight: .bold))
                                .foregroundStyle(Palette.amber)
                                .kerning(1.2)

                            Text(test.description)
                                .font(Typography.body())
                                .foregroundStyle(Color.white.opacity(0.85))
                                .lineSpacing(4)
                        }

                        // Instructions / Steps
                        VStack(alignment: .leading, spacing: 10) {
                            Text("WHAT TO EXPECT")
                                .font(Typography.caption2(weight: .bold))
                                .foregroundStyle(Palette.amber)
                                .kerning(1.2)

                            ForEach(Array(testInstructions.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Palette.amber.opacity(0.15))
                                            .frame(width: 24, height: 24)
                                        Text("\(index + 1)")
                                            .font(Typography.caption2(weight: .bold))
                                            .foregroundStyle(Palette.amber)
                                    }

                                    Text(step)
                                        .font(Typography.subheadline())
                                        .foregroundStyle(Color.white.opacity(0.8))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white.opacity(0.04))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
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

    private var testInstructions: [String] {
        switch test.id {
        case "landolt_c":
            return [
                "Hold phone at arm's length (about 40 cm / 16 in).",
                "Cover one eye with your free hand.",
                "Look at the ring and identify the direction of the opening (up, down, left, right).",
                "Repeat with the other eye when prompted."
            ]
        case "osdi":
            return [
                "Answer each question honestly based on the past week.",
                "Rate how often you felt eye irritation or blurriness.",
                "Takes less than 2 minutes to complete.",
                "Your score will be saved and tracked over time."
            ]
        default:
            return ["Follow the on-screen instructions to complete the vision assessment."]
        }
    }
}

#Preview {
    TestDetailSheet(test: .landoltC, onStart: {}, onDismiss: {})
}
