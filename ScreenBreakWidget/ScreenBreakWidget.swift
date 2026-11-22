//
//  ScreenBreakWidget.swift
//  ScreenBreakWidget
//
//  Dynamic Island / Lock Screen Live Activity for the 20-20-20 eye break —
//  shows a countdown to the next estimated reminder.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ScreenBreakWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ScreenBreakActivityAttributes.self) { context in
            ScreenBreakLockScreenView(nextBreakAt: context.state.nextBreakAt)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    ScreenBreakLeadingView()
                        .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ScreenBreakTrailingView(nextBreakAt: context.state.nextBreakAt)
                        .padding(.trailing, 8)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("Next Eye Break")
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Look 20 feet away for 20 seconds when it's time.")
                        .font(.subheadline)
                        .padding(.top, 4)
                }
            } compactLeading: {
                ScreenBreakLeadingView()
            } compactTrailing: {
                ScreenBreakTrailingView(nextBreakAt: context.state.nextBreakAt)
                    .frame(width: 44)
            } minimal: {
                ScreenBreakLeadingView()
            }
        }
    }
}

private struct ScreenBreakLeadingView: View {
    var body: some View {
        Image(systemName: "eye.fill")
            .foregroundColor(.cyan)
    }
}

private struct ScreenBreakTrailingView: View {
    let nextBreakAt: Date

    var body: some View {
        Text(nextBreakAt, style: .timer)
            .font(.caption)
            .bold()
            .foregroundColor(.cyan)
            .monospacedDigit()
    }
}

private struct ScreenBreakLockScreenView: View {
    let nextBreakAt: Date

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "eye.fill")
                .font(.title2)
                .foregroundColor(.cyan)
            VStack(alignment: .leading, spacing: 4) {
                Text("Next Eye Break")
                    .font(.headline)
                Text("Look 20 ft away for 20 seconds")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(nextBreakAt, style: .timer)
                .font(.title3)
                .monospacedDigit()
                .bold()
                .foregroundColor(.cyan)
        }
        .padding()
    }
}

// MARK: - Previews

private struct ScreenBreakPreviewData {
    static let attributes = ScreenBreakActivityAttributes()
    static let state = ScreenBreakActivityAttributes.ContentState(
        nextBreakAt: Date().addingTimeInterval(20 * 60)
    )
}

#Preview("Lock Screen", as: .content, using: ScreenBreakPreviewData.attributes) {
    ScreenBreakWidget()
} contentStates: {
    ScreenBreakPreviewData.state
}
