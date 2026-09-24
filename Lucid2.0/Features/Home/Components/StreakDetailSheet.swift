//
//  StreakDetailSheet.swift
//  Lucid2.0
//
//  Created by Antigravity on 24/09/26.
//

import SwiftUI

public struct StreakDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var streakManager = StreakManager.shared

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.04, green: 0.05, blue: 0.09)
                    .ignoresSafeArea()

                // Background Ambient Glow
                RadialGradient(
                    colors: [Palette.ember.opacity(0.18), .clear],
                    center: .top,
                    startRadius: 20,
                    endRadius: 360
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // 1. Hero Flame Badge & Count
                        heroStreakSection

                        // 2. 7-Day Activity Calendar
                        weeklyActivitySection

                        // 3. How It Is Calculated Card
                        calculationExplanationCard

                        // 4. How It Is Shared & Achievements Card
                        sharingExplanationCard

                        // 5. Share Streak Action Button
                        shareActionButton

                        Spacer().frame(height: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Streak & Habit Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(Typography.body(weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Hero Section

    private var heroStreakSection: some View {
        VStack(spacing: 16) {
            FlameBadge(count: streakManager.currentStreak)
                .scaleEffect(1.25)
                .padding(.top, 10)

            VStack(spacing: 6) {
                Text(streakManager.streakStatusTitle)
                    .font(Typography.title(weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(streakManager.streakStatusDescription)
                    .font(Typography.subheadline())
                    .foregroundStyle(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }

            // Stat pills row
            HStack(spacing: 12) {
                statPill(
                    title: "Current",
                    value: "\(streakManager.currentStreak)d",
                    icon: "flame.fill",
                    color: Palette.ember
                )

                statPill(
                    title: "Best",
                    value: "\(streakManager.bestStreak)d",
                    icon: "trophy.fill",
                    color: Palette.amber
                )

                statPill(
                    title: "Exercises",
                    value: "\(streakManager.totalExercisesCompleted)",
                    icon: "eye.fill",
                    color: Palette.honey
                )
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(red: 0.08, green: 0.11, blue: 0.20).opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Palette.ember.opacity(0.25), lineWidth: 1)
                )
        )
    }

    private func statPill(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(Typography.caption2())
                    .foregroundStyle(color)
                Text(title)
                    .font(Typography.caption(weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.6))
            }
            Text(value)
                .font(Typography.headline(weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }

    // MARK: - 7-Day Activity Matrix

    private var weeklyActivitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "calendar")
                    .font(Typography.subheadline(weight: .semibold))
                    .foregroundStyle(Palette.amber)

                Text("Last 7 Days Activity")
                    .font(Typography.headline())
                    .foregroundStyle(.white)

                Spacer()

                Text(streakManager.isCompletedToday ? "Completed Today" : "Pending Today")
                    .font(Typography.caption(weight: .medium))
                    .foregroundStyle(streakManager.isCompletedToday ? Color.green : Palette.amber)
            }

            HStack(spacing: 0) {
                ForEach(streakManager.past7Days) { day in
                    VStack(spacing: 8) {
                        Text(day.dayLetter)
                            .font(Typography.caption(weight: .semibold))
                            .foregroundStyle(day.isToday ? .white : Color.white.opacity(0.5))

                        ZStack {
                            Circle()
                                .fill(dayCircleBackground(day: day))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .strokeBorder(dayCircleBorder(day: day), lineWidth: day.isToday ? 2 : 1)
                                )

                            if day.isCompleted {
                                Image(systemName: "flame.fill")
                                    .font(Typography.caption(weight: .bold))
                                    .foregroundStyle(Palette.ember)
                            } else if day.isToday {
                                Circle()
                                    .fill(Palette.amber)
                                    .frame(width: 8, height: 8)
                            } else {
                                Circle()
                                    .fill(Color.white.opacity(0.12))
                                    .frame(width: 6, height: 6)
                            }
                        }

                        Text(day.isToday ? "Today" : "")
                            .font(Typography.caption2(weight: .medium))
                            .foregroundStyle(Palette.amber)
                            .frame(height: 12)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 6)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(red: 0.07, green: 0.09, blue: 0.16))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private func dayCircleBackground(day: WeeklyDayStatus) -> Color {
        if day.isCompleted {
            return Palette.ember.opacity(0.2)
        } else if day.isToday {
            return Palette.amber.opacity(0.12)
        } else {
            return Color.white.opacity(0.04)
        }
    }

    private func dayCircleBorder(day: WeeklyDayStatus) -> Color {
        if day.isCompleted {
            return Palette.ember.opacity(0.7)
        } else if day.isToday {
            return Palette.amber
        } else {
            return Color.white.opacity(0.08)
        }
    }

    // MARK: - How It Is Calculated Card

    private var calculationExplanationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "function")
                    .font(Typography.subheadline(weight: .semibold))
                    .foregroundStyle(Palette.amber)
                Text("How Streak is Calculated")
                    .font(Typography.headline())
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 12) {
                ruleRow(
                    number: "1",
                    title: "Complete 1 Eye Exercise Daily",
                    desc: "Finish at least one eye training exercise or your daily recommended stack before 11:59 PM each calendar day."
                )

                ruleRow(
                    number: "2",
                    title: "Consecutive Days Accumulate",
                    desc: "Every back-to-back day you complete exercises advances your streak counter by +1 day."
                )

                ruleRow(
                    number: "3",
                    title: "Midnight Reset Mechanism",
                    desc: "If a calendar day passes without any completed exercise, the streak counter resets to 0."
                )

                ruleRow(
                    number: "4",
                    title: "Streak Saver Grace Window",
                    desc: "Streak Saver in Settings provides an automatic 1-day safety net if you miss a single day, keeping your momentum alive."
                )
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(red: 0.07, green: 0.09, blue: 0.16))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    // MARK: - How It Is Shared Card

    private var sharingExplanationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .font(Typography.subheadline(weight: .semibold))
                    .foregroundStyle(Palette.ember)
                Text("How Streak is Shared & Used")
                    .font(Typography.headline())
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 12) {
                ruleRow(
                    number: "A",
                    title: "Unlocks Profile Gemstones",
                    desc: "Reaching 3-day, 7-day, and 30-day streak milestones unlocks permanent gemstone badges on your public profile."
                )

                ruleRow(
                    number: "B",
                    title: "Powers Your Lucid Score",
                    desc: "Consistent streaks feed directly into your Rest & Exercise composite score, improving overall visual health diagnostics."
                )

                ruleRow(
                    number: "C",
                    title: "Shareable Accountability",
                    desc: "Tap the button below to share your active streak and dedication with friends, family, or social media."
                )
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(red: 0.07, green: 0.09, blue: 0.16))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private func ruleRow(number: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 24, height: 24)
                Text(number)
                    .font(Typography.caption2(weight: .bold))
                    .foregroundStyle(Palette.amber)
            }
            .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Typography.subheadline(weight: .semibold))
                    .foregroundStyle(.white)

                Text(desc)
                    .font(Typography.footnote())
                    .foregroundStyle(Color.white.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Share Action Button

    private var shareActionButton: some View {
        ShareLink(
            item: streakManager.shareText,
            preview: SharePreview("Lucid Care Streak: \(streakManager.currentStreak) Days", image: Image(systemName: "flame.fill"))
        ) {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(Typography.headline())
                    .foregroundStyle(Color(red: 1.0, green: 0.88, blue: 0.35))

                Text("Share Streak Achievement")
                    .font(Typography.headline(weight: .semibold))
                    .foregroundStyle(.white)

                Image(systemName: "square.and.arrow.up")
                    .font(Typography.subheadline())
                    .foregroundStyle(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Palette.ember, Color(red: 0.85, green: 0.28, blue: 0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Palette.ember.opacity(0.4), radius: 12, y: 4)
            )
        }
    }
}
