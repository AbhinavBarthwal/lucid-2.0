//
//  TestDefinition.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import Foundation

public struct TestDefinition: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let description: String
    public let imageName: String
    public let estimatedMinutes: Int
    public let systemIcon: String

    public var durationFormatted: String {
        "~\(estimatedMinutes) min\(estimatedMinutes == 1 ? "" : "s")"
    }

    // MARK: - Built-in Test Catalog

    public static let landoltC = TestDefinition(
        id: "landolt_c",
        title: "Visual Acuity",
        subtitle: "Check how sharp your vision is at a distance",
        description: "The Landolt C test measures visual acuity — how clearly you can see fine details. You'll look at ring-shaped letters and say which direction the gap faces. This tests each eye individually.",
        imageName: "test_landolt_c",
        estimatedMinutes: 2,
        systemIcon: "eye.circle"
    )

    public static let osdi = TestDefinition(
        id: "osdi",
        title: "Dry Eye Check",
        subtitle: "Screen comfort and dry eye symptom assessment",
        description: "The OSDI (Ocular Surface Disease Index) questionnaire checks for dry eye symptoms caused by screen use. Answer 12 simple questions about your recent eye comfort and screen experience.",
        imageName: "test_osdi",
        estimatedMinutes: 2,
        systemIcon: "drop.circle"
    )

    public static let catalog: [TestDefinition] = [landoltC, osdi]
}
