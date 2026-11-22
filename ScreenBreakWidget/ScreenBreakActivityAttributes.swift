//
//  ScreenBreakActivityAttributes.swift
//  ScreenBreakWidget
//
//  Mirrors Lucid2.0/Services/ScreenBreakActivityAttributes.swift — ActivityAttributes
//  types must be compiled into both the app target (which starts the activity) and
//  this widget extension target (which renders it).
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
