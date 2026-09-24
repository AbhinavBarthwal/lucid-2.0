//
//  UserProfile.swift
//  Lucid2.0
//
//  Created by Antigravity on 21/09/26.
//

import Foundation

public struct UserProfile: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var email: String
    public var leftEyePower: Double
    public var rightEyePower: Double
    public var hasGlassesOrContacts: Bool
    public var previousConditions: [String]
    public var estimatedDailyScreenTimeHours: Double
    public var actualDailyScreenTimeHours: Double?
    public var primaryActivity: String
    public var peakFatigueTime: String
    public var recommendedExerciseIds: [String]
    public var baselineRestScore: Int
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String = "",
        email: String = "",
        leftEyePower: Double = 0.0,
        rightEyePower: Double = 0.0,
        hasGlassesOrContacts: Bool = false,
        previousConditions: [String] = [],
        estimatedDailyScreenTimeHours: Double = 6.0,
        actualDailyScreenTimeHours: Double? = nil,
        primaryActivity: String = "Coding & Reading",
        peakFatigueTime: String = "Late Day (5–8)",
        recommendedExerciseIds: [String] = [],
        baselineRestScore: Int = 70,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.leftEyePower = leftEyePower
        self.rightEyePower = rightEyePower
        self.hasGlassesOrContacts = hasGlassesOrContacts
        self.previousConditions = previousConditions
        self.estimatedDailyScreenTimeHours = estimatedDailyScreenTimeHours
        self.actualDailyScreenTimeHours = actualDailyScreenTimeHours
        self.primaryActivity = primaryActivity
        self.peakFatigueTime = peakFatigueTime
        self.recommendedExerciseIds = recommendedExerciseIds
        self.baselineRestScore = baselineRestScore
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
