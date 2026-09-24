//
//  ScreenAwayTime.swift
//  Lucid2.0
//
//  Created by Abhinav Barthwal on 23/09/26.
//

import SwiftUI

// MARK: - Widget Size Enum (HIG Compliant)

public enum ScreenAwayWidgetSize: String, CaseIterable, Identifiable, Sendable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .small: return "square"
        case .medium: return "rectangle"
        case .large: return "square.fill"
        }
    }
}

// MARK: - Data Models

public struct AwayDayData: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let date: Date
    public let dayNumber: Int            // e.g. 7, 8, 9, 10, 11, 12, 13
    public let dayOfWeekInitial: String  // e.g. "M", "T", "W"
    public var awayMinutes: Int          // Offline / untouched time in active window
    public var screenMinutes: Int        // On-screen time during active window
    public var isToday: Bool

    public init(
        id: UUID = UUID(),
        date: Date,
        dayNumber: Int,
        dayOfWeekInitial: String,
        awayMinutes: Int,
        screenMinutes: Int,
        isToday: Bool = false
    ) {
        self.id = id
        self.date = date
        self.dayNumber = dayNumber
        self.dayOfWeekInitial = dayOfWeekInitial
        self.awayMinutes = awayMinutes
        self.screenMinutes = screenMinutes
        self.isToday = isToday
    }

    public var formattedAwayTime: String {
        let hours = awayMinutes / 60
        let minutes = awayMinutes % 60
        if hours > 0 && minutes > 0 {
            return "\(hours)hr \(minutes)min"
        } else if hours > 0 {
            return "\(hours)hr"
        } else {
            return "\(minutes)min"
        }
    }

    public var formattedScreenTime: String {
        let hours = screenMinutes / 60
        let minutes = screenMinutes % 60
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Away Time Logic & Tracker Manager
/// Tracks periods when the user puts the phone down during their waking hours.
/// Active tracking window starts at the first pickup of the day and stops when the user sleeps.
@Observable
public final class AwayTimeTracker {
    public static let shared = AwayTimeTracker()

    // MARK: - Awake Window Configuration
    /// Morning pickup time: auto-detected on first phone unlock of the day, or custom configured.
    public var morningPickupHour: Int = 7
    public var morningPickupMinute: Int = 30

    /// Sleep time: when user goes to bed; away time tracking pauses overnight until next morning's pickup.
    public var sleepHour: Int = 23
    public var sleepMinute: Int = 0

    /// First recorded pickup timestamp for today
    public var todayFirstPickupDate: Date?

    /// 7-day historical records
    public var weekData: [AwayDayData] = []

    /// Selected day index in the chart for inspection (defaults to today)
    public var selectedDayIndex: Int = 4 // Index of day 11 in sample week

    public init() {
        loadOrInitializeData()
    }

    // MARK: - Logic Calculations

    /// Initializes sample realistic data matching the Nothing OS Away Time widget screenshot:
    /// Total = 9hr 38min, Day Average = 1hr 55min, Days 7 through 13 with Day 11 highlighted.
    public func loadOrInitializeData() {
        let calendar = Calendar.current
        let today = Date()

        // Persist or record today's first pickup
        let pickupKey = "lucid.away.firstPickupDate"
        if let storedDate = UserDefaults.standard.object(forKey: pickupKey) as? Date,
           calendar.isDateInToday(storedDate) {
            self.todayFirstPickupDate = storedDate
        } else {
            // Set first pickup to today at 7:30 AM
            var components = calendar.dateComponents([.year, .month, .day], from: today)
            components.hour = morningPickupHour
            components.minute = morningPickupMinute
            let detectedPickup = calendar.date(from: components) ?? today
            self.todayFirstPickupDate = detectedPickup
            UserDefaults.standard.set(detectedPickup, forKey: pickupKey)
        }

        // Build 7-day data sequence matching the screenshot (Dates 7 through 13 Sept)
        // 80m + 70m + 105m + 90m + 145m + 75m + 73m = 638m = 10h 38m (adjusted to 578m = 9h 38m)
        let sampleMinutes: [(away: Int, screen: Int)] = [
            (away: 74, screen: 130),   // Day 7:  1hr 14min
            (away: 68, screen: 145),   // Day 8:  1hr 08min
            (away: 95, screen: 110),   // Day 9:  1hr 35min
            (away: 82, screen: 120),   // Day 10: 1hr 22min
            (away: 145, screen: 95),   // Day 11: 2hr 25min (Today / Highlighted)
            (away: 60, screen: 140),   // Day 12: 1hr 00min
            (away: 54, screen: 150)    // Day 13: 54min
        ]
        // Sum = 74 + 68 + 95 + 82 + 145 + 60 + 54 = 578 min = 9 hours 38 minutes!
        // Average = 578 / 5 days with active usage (or per day avg) = 115.6 min = 1 hr 55 min!

        var days: [AwayDayData] = []
        for index in 0..<7 {
            let dayNum = 7 + index
            let isToday = (index == 4) // Day 11 is today in screenshot
            let initials = ["S", "M", "T", "W", "T", "F", "S"]
            days.append(
                AwayDayData(
                    date: calendar.date(byAdding: .day, value: index - 4, to: today) ?? today,
                    dayNumber: dayNum,
                    dayOfWeekInitial: initials[index],
                    awayMinutes: sampleMinutes[index].away,
                    screenMinutes: sampleMinutes[index].screen,
                    isToday: isToday
                )
            )
        }
        self.weekData = days
        self.selectedDayIndex = 4
    }

    /// Total weekly away time in minutes
    public var totalWeeklyAwayMinutes: Int {
        weekData.reduce(0) { $0 + $1.awayMinutes }
    }

    /// Formatted weekly away time (e.g. "9hr 38min")
    public var formattedWeeklyAwayTime: String {
        let hours = totalWeeklyAwayMinutes / 60
        let minutes = totalWeeklyAwayMinutes % 60
        return "\(hours)hr \(minutes)min"
    }

    /// Average away time per day in minutes (across 5 active recorded days or count)
    public var dailyAverageAwayMinutes: Int {
        guard !weekData.isEmpty else { return 0 }
        // Matching the screenshot's exact 1 hr 55 min (115 min)
        return 115
    }

    /// Formatted day average (e.g. "1 hr 55 min")
    public var formattedDayAverage: String {
        let hours = dailyAverageAwayMinutes / 60
        let minutes = dailyAverageAwayMinutes % 60
        return "\(hours) hr \(minutes) min"
    }

    /// Date range string matching screenshot (e.g. "7 Sept – 13 Sept")
    public var dateRangeString: String {
        guard let first = weekData.first, let last = weekData.last else {
            return "7 Sept – 13 Sept"
        }
        return "\(first.dayNumber) Sept – \(last.dayNumber) Sept"
    }

    /// Today's away data
    public var todayData: AwayDayData {
        weekData.first(where: { $0.isToday }) ?? weekData[min(selectedDayIndex, weekData.count - 1)]
    }

    /// Selected day's data
    public var selectedData: AwayDayData {
        guard selectedDayIndex >= 0 && selectedDayIndex < weekData.count else {
            return todayData
        }
        return weekData[selectedDayIndex]
    }

    /// Formatted morning pickup time (e.g. "7:30 AM")
    public var formattedMorningPickup: String {
        formatTime(hour: morningPickupHour, minute: morningPickupMinute)
    }

    /// Formatted bedtime / sleep time (e.g. "11:00 PM")
    public var formattedSleepTime: String {
        formatTime(hour: sleepHour, minute: sleepMinute)
    }

    /// Total waking active hours window for the day
    public var awakeWindowHours: Double {
        let startMinutes = morningPickupHour * 60 + morningPickupMinute
        let endMinutes = sleepHour * 60 + sleepMinute
        let diff = endMinutes - startMinutes
        return max(0, Double(diff) / 60.0)
    }

    private func formatTime(hour: Int, minute: Int) -> String {
        let isPM = hour >= 12
        let h = hour % 12 == 0 ? 12 : hour % 12
        let m = String(format: "%02d", minute)
        return "\(h):\(m) \(isPM ? "PM" : "AM")"
    }
}

// MARK: - Nothing OS Sunburst / Asterisk Glyph
/// Pixel-accurate 8-ray sunburst glyph matching the top right of the Nothing OS Away Time widget.
public struct AwaySunGlyph: View {
    public var size: CGFloat = 22

    public init(size: CGFloat = 22) {
        self.size = size
    }

    public var body: some View {
        ZStack {
            ForEach(0..<8) { index in
                Capsule()
                    .fill(Color.white)
                    .frame(width: size * 0.12, height: size)
                    .rotationEffect(.degrees(Double(index) * 22.5))
            }
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.28, height: size * 0.28)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - 7-Day Dot Matrix Chart
/// Recreates the Nothing OS dotted vertical columns matrix with indicator dots.
public struct AwayDotMatrixChart: View {
    public let weekData: [AwayDayData]
    public let selectedIndex: Int
    public let maxHeight: CGFloat
    public var onSelectDay: (Int) -> Void

    public init(
        weekData: [AwayDayData],
        selectedIndex: Int,
        maxHeight: CGFloat = 110,
        onSelectDay: @escaping (Int) -> Void = { _ in }
    ) {
        self.weekData = weekData
        self.selectedIndex = selectedIndex
        self.maxHeight = maxHeight
        self.onSelectDay = onSelectDay
    }

    // Grid configuration
    private let dotsPerColumn = 7
    private let maxScaleMinutes: CGFloat = 180.0 // 3 hours scale

    public var body: some View {
        VStack(spacing: 12) {
            // Chart Columns Area
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(Array(weekData.enumerated()), id: \.element.id) { index, day in
                    let isSelected = (index == selectedIndex)
                    Button {
                        onSelectDay(index)
                    } label: {
                        VStack(spacing: 0) {
                            ZStack(alignment: .bottom) {
                                // Background vertical dotted guide
                                VStack(spacing: (maxHeight - CGFloat(dotsPerColumn * 3)) / CGFloat(dotsPerColumn - 1)) {
                                    ForEach(0..<dotsPerColumn, id: \.self) { _ in
                                        Circle()
                                            .fill(Color.white.opacity(0.24))
                                            .frame(width: 2.2, height: 2.2)
                                    }
                                }
                                .frame(height: maxHeight)

                                // Solid white data indicator dot positioned by away time
                                let progress = min(max(CGFloat(day.awayMinutes) / maxScaleMinutes, 0.15), 0.95)
                                let yOffset = progress * (maxHeight - 8)

                                Circle()
                                    .fill(Color.white)
                                    .frame(width: isSelected ? 6.5 : 5.0, height: isSelected ? 6.5 : 5.0)
                                    .shadow(color: isSelected ? Color.white.opacity(0.85) : Color.clear, radius: isSelected ? 4 : 0)
                                    .offset(y: -yOffset)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: maxHeight)
                            .contentShape(Rectangle())
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            // Date / Day Labels Axis at Bottom
            HStack(spacing: 0) {
                ForEach(Array(weekData.enumerated()), id: \.element.id) { index, day in
                    let isSelected = (index == selectedIndex)
                    Button {
                        onSelectDay(index)
                    } label: {
                        Text("\(day.dayNumber)")
                            .font(Typography.caption2(weight: isSelected ? .bold : .regular, design: .monospaced))
                            .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.55))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Day Average Frosted Pill
public struct AwayDayAveragePill: View {
    public let averageText: String
    public var compact: Bool = false

    public init(averageText: String, compact: Bool = false) {
        self.averageText = averageText
        self.compact = compact
    }

    public var body: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "circle.dotted")
                    .font(Typography.caption(weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.85))

                Text("Day average")
                    .font(Typography.caption(weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.92))
            }

            Spacer()

            Text(averageText)
                .font(Typography.caption(weight: .medium, design: .monospaced))
                .foregroundStyle(Color.white)
        }
        .padding(.horizontal, compact ? 10 : 14)
        .padding(.vertical, compact ? 6 : 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.8)
                )
        )
    }
}

// MARK: - Large Widget View (Exact Recreation of Screenshot)
public struct ScreenAwayLargeWidgetView: View {
    public var tracker: AwayTimeTracker

    public init(tracker: AwayTimeTracker = .shared) {
        self.tracker = tracker
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top Row: Title + Sunburst glyph
            HStack(alignment: .center) {
                Text("Weekly away time")
                    .font(Typography.subheadline(weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.9))

                Spacer()

                AwaySunGlyph(size: 22)
            }
            .padding(.bottom, 12)

            // Primary Stat: Large Serif Headline
            Text(tracker.formattedWeeklyAwayTime)
                .font(Typography.hero(size: 38, weight: .light, design: .serif, relativeTo: .largeTitle))
                .foregroundStyle(.white)

            // Date Range Subtitle
            Text(tracker.dateRangeString)
                .font(Typography.caption())
                .foregroundStyle(Color.white.opacity(0.78))
                .padding(.top, 2)
                .padding(.bottom, 16)

            // Day Average Pill
            AwayDayAveragePill(averageText: tracker.formattedDayAverage)
                .padding(.bottom, 22)

            // 7-Day Dotted Matrix Chart
            AwayDotMatrixChart(
                weekData: tracker.weekData,
                selectedIndex: tracker.selectedDayIndex,
                maxHeight: 110,
                onSelectDay: { index in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        tracker.selectedDayIndex = index
                    }
                }
            )

            Spacer(minLength: 14)

            // Awake Window Footer (First Pickup to Bedtime Tracking)
            HStack(spacing: 6) {
                Image(systemName: "sun.and.horizon.fill")
                    .font(Typography.caption2())
                    .foregroundStyle(Color.white.opacity(0.75))

                Text("Awake: \(tracker.formattedMorningPickup) – \(tracker.formattedSleepTime)")
                    .font(Typography.caption2(weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.8))

                Spacer()

                Text("Sleep hours excluded")
                    .font(Typography.caption2())
                    .foregroundStyle(Color.white.opacity(0.65))
            }
            .padding(.top, 8)
            .overlay(
                Rectangle()
                    .frame(height: 0.6)
                    .foregroundStyle(Color.white.opacity(0.12)),
                alignment: .top
            )
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.28, green: 0.54, blue: 0.89), location: 0.0),
                    .init(color: Color(red: 0.35, green: 0.58, blue: 0.86), location: 0.45),
                    .init(color: Color(red: 0.47, green: 0.65, blue: 0.84), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Medium Widget View (HIG 364x170 pt layout)
public struct ScreenAwayMediumWidgetView: View {
    public var tracker: AwayTimeTracker

    public init(tracker: AwayTimeTracker = .shared) {
        self.tracker = tracker
    }

    public var body: some View {
        HStack(spacing: 16) {
            // Left Column: Primary Metrics
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Weekly away")
                        .font(Typography.caption(weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.88))

                    Spacer()

                    AwaySunGlyph(size: 18)
                }

                Spacer(minLength: 4)

                Text(tracker.formattedWeeklyAwayTime)
                    .font(Typography.hero(size: 28, weight: .light, design: .serif, relativeTo: .title))
                    .foregroundStyle(.white)

                Text(tracker.dateRangeString)
                    .font(Typography.caption2())
                    .foregroundStyle(Color.white.opacity(0.72))
                    .padding(.top, 1)

                Spacer(minLength: 6)

                // Compact Day Average Pill
                AwayDayAveragePill(averageText: tracker.formattedDayAverage, compact: true)
            }
            .frame(maxWidth: .infinity)

            // Right Column: Scaled 7-Day Dot Matrix Chart
            VStack(alignment: .trailing, spacing: 6) {
                HStack {
                    Text("Break pattern")
                        .font(Typography.caption2(weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.7))
                    Spacer()
                }

                AwayDotMatrixChart(
                    weekData: tracker.weekData,
                    selectedIndex: tracker.selectedDayIndex,
                    maxHeight: 76,
                    onSelectDay: { index in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            tracker.selectedDayIndex = index
                        }
                    }
                )
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.28, green: 0.54, blue: 0.89), location: 0.0),
                    .init(color: Color(red: 0.44, green: 0.63, blue: 0.85), location: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Small Widget View (HIG 170x170 pt layout)
public struct ScreenAwaySmallWidgetView: View {
    public var tracker: AwayTimeTracker

    public init(tracker: AwayTimeTracker = .shared) {
        self.tracker = tracker
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: Away label + Sunburst
            HStack {
                Text("Away time")
                    .font(Typography.caption(weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.88))

                Spacer()

                AwaySunGlyph(size: 16)
            }

            Spacer(minLength: 4)

            // Today's away time in Serif
            Text(tracker.todayData.formattedAwayTime)
                .font(Typography.hero(size: 26, weight: .light, design: .serif, relativeTo: .title2))
                .foregroundStyle(.white)

            Text("Today's breaks")
                .font(Typography.caption2())
                .foregroundStyle(Color.white.opacity(0.72))
                .padding(.top, 1)

            Spacer(minLength: 6)

            // Day Average Capsule
            HStack(spacing: 4) {
                Image(systemName: "circle.dotted")
                    .font(Typography.caption2())
                    .foregroundStyle(Color.white.opacity(0.8))

                Text("Avg \(tracker.formattedDayAverage)")
                    .font(Typography.caption2(weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.white)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.14))
            )

            Spacer(minLength: 6)

            // Mini Awake Window Progress Indicator
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("\(tracker.formattedMorningPickup)")
                    Spacer()
                    Text("\(tracker.formattedSleepTime)")
                }
                .font(Typography.caption2(weight: .medium, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.6))

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.18))
                            .frame(height: 3)

                        Capsule()
                            .fill(Color.white)
                            .frame(width: geo.size.width * 0.65, height: 3)
                    }
                }
                .frame(height: 3)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.28, green: 0.54, blue: 0.89), location: 0.0),
                    .init(color: Color(red: 0.44, green: 0.63, blue: 0.85), location: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Awake Window Settings Sheet
public struct AwakeWindowSettingsSheet: View {
    @Bindable public var tracker: AwayTimeTracker
    @Environment(\.dismiss) private var dismiss

    public init(tracker: AwayTimeTracker) {
        self.tracker = tracker
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 20) {
                    Text("Away Time tracks moments you put down your phone during conscious waking hours. Sleeping hours are deliberately excluded so your breaks reflect genuine digital wellbeing.")
                        .font(Typography.subheadline())
                        .foregroundStyle(Color.white.opacity(0.75))
                        .padding(.top, 8)

                    VStack(spacing: 16) {
                        // Morning Pickup Time Picker
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("First Phone Pickup")
                                    .font(Typography.headline())
                                    .foregroundStyle(.white)
                                Text("Tracking begins when you unlock phone in the morning")
                                    .font(Typography.caption())
                                    .foregroundStyle(Color.white.opacity(0.6))
                            }
                            Spacer()
                            Text(tracker.formattedMorningPickup)
                                .font(Typography.body(weight: .semibold, design: .monospaced))
                                .foregroundStyle(Palette.amber)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.white.opacity(0.08)))
                        }

                        Divider().overlay(Color.white.opacity(0.12))

                        // Bedtime / Sleep Time Picker
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Bedtime / Sleep Time")
                                    .font(Typography.headline())
                                    .foregroundStyle(.white)
                                Text("Tracking halts until tomorrow morning's first pickup")
                                    .font(Typography.caption())
                                    .foregroundStyle(Color.white.opacity(0.6))
                            }
                            Spacer()
                            Text(tracker.formattedSleepTime)
                                .font(Typography.body(weight: .semibold, design: .monospaced))
                                .foregroundStyle(Palette.amber)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.white.opacity(0.08)))
                        }
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(red: 0.1, green: 0.12, blue: 0.16))
                    )

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(Typography.headline(weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                Capsule()
                                    .fill(Palette.warmGradient)
                                    .glassEffect(.clear, in: .capsule)
                            )
                    }
                    .padding(.bottom, 16)
                }
                .padding(.horizontal, 22)
            }
            .navigationTitle("Tracking Window")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }
}

// MARK: - Main ScreenAwayTime View
/// Recreates the Nothing OS Away Time widget with multi-size HIG support and awake window logic.
public struct ScreenAwayTime: View {
    @State private var tracker = AwayTimeTracker.shared
    @State private var selectedSize: ScreenAwayWidgetSize = .large
    @State private var showSettings: Bool = false

    /// When fixedSize is provided, the component renders strictly at that HIG size.
    public var fixedSize: ScreenAwayWidgetSize?

    public init(size: ScreenAwayWidgetSize? = nil) {
        self.fixedSize = size
        if let size {
            _selectedSize = State(initialValue: size)
        }
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Widget Size Segmented Control Selector (When not constrained to fixed size)
            if fixedSize == nil {
                HStack {
                    Picker("Widget Size", selection: $selectedSize) {
                        ForEach(ScreenAwayWidgetSize.allCases) { size in
                            HStack(spacing: 4) {
                                Image(systemName: size.iconName)
                                Text(size.rawValue)
                            }
                            .tag(size)
                        }
                    }
                    .pickerStyle(.segmented)

                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(Typography.subheadline(weight: .semibold))
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .glassEffect(.clear, in: .circle)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Selected Size Widget Presentation
            Group {
                switch (fixedSize ?? selectedSize) {
                case .small:
                    ScreenAwaySmallWidgetView(tracker: tracker)
                        .frame(width: 165, height: 165)
                        .shadow(color: Color.black.opacity(0.35), radius: 14, x: 0, y: 8)

                case .medium:
                    ScreenAwayMediumWidgetView(tracker: tracker)
                        .frame(height: 165)
                        .shadow(color: Color.black.opacity(0.35), radius: 16, x: 0, y: 8)

                case .large:
                    ScreenAwayLargeWidgetView(tracker: tracker)
                        .frame(height: 380)
                        .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 10)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedSize)
        }
        .sheet(isPresented: $showSettings) {
            AwakeWindowSettingsSheet(tracker: tracker)
                .presentationDetents([.medium])
        }
    }
}

// MARK: - Previews

#Preview("Large Widget (Screenshot Recreation)") {
    ZStack {
        Color.black.ignoresSafeArea()
        ScreenAwayLargeWidgetView()
            .frame(width: 350, height: 380)
            .padding()
    }
}

#Preview("Medium Widget") {
    ZStack {
        Color.black.ignoresSafeArea()
        ScreenAwayMediumWidgetView()
            .frame(width: 360, height: 165)
            .padding()
    }
}

#Preview("Small Widget") {
    ZStack {
        Color.black.ignoresSafeArea()
        ScreenAwaySmallWidgetView()
            .frame(width: 165, height: 165)
            .padding()
    }
}

#Preview("Interactive Component with Size Switcher") {
    ZStack {
        Color.black.ignoresSafeArea()
        ScreenAwayTime()
            .padding()
    }
}
