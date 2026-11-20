//
//  Lucid2_0App.swift
//  Lucid2.0
//
//  Created by Abhinav Barthwal on 07/09/26.
//

import SwiftUI

@main
struct Lucid2_0App: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Registers NotificationEngine as the UNUserNotificationCenter delegate
        // before any notification tap (including a cold launch) can arrive.
        _ = NotificationEngine.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                NotificationEngine.shared.refreshAllSchedules()
            }
        }
    }
}
