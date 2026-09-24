//
//  TestScheduleManager.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import Foundation
import SwiftUI

@Observable
public final class TestScheduleManager {
    public static let shared = TestScheduleManager()

    public var isTestDue: Bool = true
    public var testsCount: Int = 2
    public var estimatedMinutes: Int = 4
    public var lastCompletedDate: Date?

    private let lastCompletedKey = "lucid_vision_tests_last_completed"
    private let biweeklyIntervalDays: Int = 14

    public init() {
        checkDueStatus()
    }

    public func checkDueStatus() {
        if let timestamp = UserDefaults.standard.object(forKey: lastCompletedKey) as? Double {
            let completed = Date(timeIntervalSince1970: timestamp)
            self.lastCompletedDate = completed

            if let nextDue = Calendar.current.date(byAdding: .day, value: biweeklyIntervalDays, to: completed) {
                self.isTestDue = Date() >= nextDue
                return
            }
        }

        // Fresh install / no tests taken yet -> Test is due!
        self.isTestDue = true
    }

    public func completeTestBattery(cTestScore: Double = 6.0, osdiScore: Double = 15.0) {
        let now = Date()
        self.lastCompletedDate = now
        UserDefaults.standard.set(now.timeIntervalSince1970, forKey: lastCompletedKey)
        self.isTestDue = false

        // Update score engine with latest test results
        LucidScoreEngine.shared.recordTestResults(cTestAcuity: cTestScore, osdiScore: osdiScore)
    }

    public func resetTestDue() {
        UserDefaults.standard.removeObject(forKey: lastCompletedKey)
        self.lastCompletedDate = nil
        self.isTestDue = true
    }
}
