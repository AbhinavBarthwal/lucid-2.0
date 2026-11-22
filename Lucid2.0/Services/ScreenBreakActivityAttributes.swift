//
//  ScreenBreakActivityAttributes.swift
//  Lucid2.0
//
//  Shared ActivityKit contract for the 20-20-20 Live Activity. This same
//  struct also exists in the ScreenBreakWidgetExtension target so it can
//  render the activity — ActivityAttributes types must be visible to both
//  the app that starts the activity and the widget extension that draws it.
//

import ActivityKit
import Foundation

public struct ScreenBreakActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var nextBreakAt: Date

        public init(nextBreakAt: Date) {
            self.nextBreakAt = nextBreakAt
        }
    }

    public init() {}
}
