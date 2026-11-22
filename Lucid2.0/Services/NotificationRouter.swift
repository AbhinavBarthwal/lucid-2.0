//
//  NotificationRouter.swift
//  Lucid2.0
//
//  Shared pending-route signal set by NotificationEngine when the user taps a
//  local notification, so ContentView/ProtectView/HomeView can react and land
//  the user exactly where that notification promised (e.g. the 20-20-20 flow).
//

import Foundation

@Observable
public final class NotificationRouter {
    public static let shared = NotificationRouter()

    public enum Route: Equatable {
        case none
        case exercise
        case visionTest
        case screenBreak
    }

    public var pendingRoute: Route = .none

    private init() {}
}
