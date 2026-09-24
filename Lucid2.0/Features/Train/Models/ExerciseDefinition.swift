//
//  ExerciseDefinition.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import Foundation

public enum ExerciseCategory: String, Codable, Sendable {
    case tracking
    case blinking
    case accommodation
    case mobility
    case relaxation
}

public enum PhysicalTarget: String, Codable, Sendable {
    case eye
    case neck
}

public enum TimeOfDaySlot: String, Codable, Sendable {
    case morning
    case midday
    case evening
    case anytime
}

public struct ExerciseDefinition: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let category: ExerciseCategory
    public let physicalTarget: PhysicalTarget
    public let estimatedDurationSeconds: Int
    public let idealTimeSlot: TimeOfDaySlot
    public let systemIcon: String
    /// Asset catalog image name for the exercise card thumbnail
    public let imageName: String
    /// Whether this exercise uses ARKit face tracking (camera required)
    public let requiresCamera: Bool
    /// Short reason shown on Recommended card (~8-12 words)
    public let recommendationReason: String

    public init(
        id: String,
        title: String,
        subtitle: String,
        category: ExerciseCategory,
        physicalTarget: PhysicalTarget = .eye,
        estimatedDurationSeconds: Int,
        idealTimeSlot: TimeOfDaySlot,
        systemIcon: String,
        imageName: String,
        requiresCamera: Bool = false,
        recommendationReason: String = ""
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.category = category
        self.physicalTarget = physicalTarget
        self.estimatedDurationSeconds = estimatedDurationSeconds
        self.idealTimeSlot = idealTimeSlot
        self.systemIcon = systemIcon
        self.imageName = imageName
        self.requiresCamera = requiresCamera
        self.recommendationReason = recommendationReason
    }

    public var durationMinutesFormatted: String {
        let mins = max(1, Int(ceil(Double(estimatedDurationSeconds) / 60.0)))
        return "\(mins) min\(mins == 1 ? "" : "s")"
    }

    // MARK: - Built-in Exercise Catalog

    public static let smoothPursuits = ExerciseDefinition(
        id: "smooth_pursuits",
        title: "Smooth Pursuits",
        subtitle: "Track the moving target to strengthen visual stability",
        category: .tracking,
        physicalTarget: .eye,
        estimatedDurationSeconds: 135,
        idealTimeSlot: .morning,
        systemIcon: "circle.circle.fill",
        imageName: "exercise_smooth_pursuits",
        requiresCamera: true,
        recommendationReason: "Tracking helps rebuild focus after screen strain"
    )

    public static let saccadicJumps = ExerciseDefinition(
        id: "saccadic_jumps",
        title: "Saccadic Jumps",
        subtitle: "Rapid eye hops to sharpen your visual response time",
        category: .tracking,
        physicalTarget: .eye,
        estimatedDurationSeconds: 70,
        idealTimeSlot: .morning,
        systemIcon: "bolt.horizontal.fill",
        imageName: "exercise_saccadic_jumps",
        requiresCamera: true,
        recommendationReason: "Saccadic training boosts your eyes' responsiveness"
    )

    public static let blinkTraining = ExerciseDefinition(
        id: "blink_training",
        title: "Blink Training",
        subtitle: "Timed blink pulses to keep eyes moist and refreshed",
        category: .blinking,
        physicalTarget: .eye,
        estimatedDurationSeconds: 90,
        idealTimeSlot: .morning,
        systemIcon: "eye.fill",
        imageName: "exercise_blink_training",
        requiresCamera: true,
        recommendationReason: "Your dry eye score suggests blinking exercises help most"
    )

    public static let neckMobility = ExerciseDefinition(
        id: "neck_mobility",
        title: "Neck Mobility Drill",
        subtitle: "Release desk tension and reset cervical posture",
        category: .mobility,
        physicalTarget: .neck,
        estimatedDurationSeconds: 120,
        idealTimeSlot: .midday,
        systemIcon: "figure.walk",
        imageName: "exercise_neck_mobility",
        requiresCamera: true,
        recommendationReason: "Neck mobility reduces headaches caused by screen posture"
    )

    public static let nearFarFocus = ExerciseDefinition(
        id: "near_far_focus",
        title: "Near Far Focus",
        subtitle: "Alternate depth focus to prevent screen lock",
        category: .accommodation,
        physicalTarget: .eye,
        estimatedDurationSeconds: 110,
        idealTimeSlot: .midday,
        systemIcon: "viewfinder",
        imageName: "exercise_near_far_focus",
        requiresCamera: false,
        recommendationReason: "Alternating focus relieves eye fatigue from screens"
    )

    public static let figure8 = ExerciseDefinition(
        id: "figure_8",
        title: "Figure 8 Tracking",
        subtitle: "Trace a wide infinity loop to deeply relax eye muscles",
        category: .relaxation,
        physicalTarget: .eye,
        estimatedDurationSeconds: 90,
        idealTimeSlot: .evening,
        systemIcon: "infinity",
        imageName: "exercise_figure_eight",
        requiresCamera: false,
        recommendationReason: "Relax eye muscles and wind down from a full screen day"
    )

    public static let pencilPushup = ExerciseDefinition(
        id: "pencil_pushup",
        title: "Pencil Push-up",
        subtitle: "Move your phone closer and further to train convergence",
        category: .accommodation,
        physicalTarget: .eye,
        estimatedDurationSeconds: 60,
        idealTimeSlot: .evening,
        systemIcon: "arrow.up.and.down.and.sparkles",
        imageName: "exercise_pencil_pushup",
        requiresCamera: false,
        recommendationReason: "Strengthens eye convergence and sharpens near focus"
    )

    public static let catalog: [ExerciseDefinition] = [
        smoothPursuits,
        saccadicJumps,
        blinkTraining,
        neckMobility,
        nearFarFocus,
        figure8,
        pencilPushup
    ]

    public static var eyeExercises: [ExerciseDefinition] {
        catalog.filter { $0.physicalTarget == .eye }
    }

    public static var neckExercises: [ExerciseDefinition] {
        catalog.filter { $0.physicalTarget == .neck }
    }
}
