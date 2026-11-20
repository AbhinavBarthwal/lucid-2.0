//
//  ProfileView.swift
//  Lucid2.0
//
//  Created by Antigravity on 24/09/26.
//

import SwiftUI

// MARK: - Gem Milestone Model

public struct GemMilestone: Identifiable, Equatable {
    public let id: String
    public let displayName: String
    public let subtitle: String
    public let color: Color
    public let assetName: String
    public let fallbackSymbol: String
    public let unlockCondition: GemUnlockCondition
    public let unlockDescription: String
    public let loreDescription: String

    public static func == (lhs: GemMilestone, rhs: GemMilestone) -> Bool {
        lhs.id == rhs.id
    }
}

public enum GemUnlockCondition: Equatable {
    case firstExercise
    case streak(days: Int)
    case exercisesCount(count: Int)
    case screenTimeSaved(hours: Double)
    case masterAll

    public func isUnlocked(exercises: Int, streak: Int, screenTimeSaved: Double) -> Bool {
        switch self {
        case .firstExercise:
            return exercises >= 1
        case .streak(let days):
            return streak >= days
        case .exercisesCount(let count):
            return exercises >= count
        case .screenTimeSaved(let hours):
            return screenTimeSaved >= hours
        case .masterAll:
            return exercises >= 50 && streak >= 30
        }
    }

    public func progress(exercises: Int, streak: Int, screenTimeSaved: Double) -> (current: Int, total: Int)? {
        switch self {
        case .firstExercise:
            return (min(exercises, 1), 1)
        case .streak(let days):
            return (min(streak, days), days)
        case .exercisesCount(let count):
            return (min(exercises, count), count)
        case .screenTimeSaved(let hours):
            return (min(Int(screenTimeSaved), Int(hours)), Int(hours))
        case .masterAll:
            let exPart = min(exercises, 50)
            let stPart = min(streak, 30)
            return (exPart + stPart, 80)
        }
    }
}

public let gemCatalog: [GemMilestone] = [
    GemMilestone(
        id: "topaz_dawn",
        displayName: "Topaz Dawn",
        subtitle: "First Session",
        color: Color(red: 1.0, green: 0.72, blue: 0.18),
        assetName: "gem_topaz",
        fallbackSymbol: "sun.max.fill",
        unlockCondition: .firstExercise,
        unlockDescription: "Complete 1 vision session",
        loreDescription: "The primordial spark of ocular restoration. Glowing with warm solar radiance, Topaz Dawn awakens photoreceptor sensitivity and marks the beginning of conscious vision training."
    ),
    GemMilestone(
        id: "amethyst_flow",
        displayName: "Amethyst Flow",
        subtitle: "3-Day Streak",
        color: Color(red: 0.73, green: 0.44, blue: 0.98),
        assetName: "gem_amethyst",
        fallbackSymbol: "sparkles",
        unlockCondition: .streak(days: 3),
        unlockDescription: "Maintain a 3-day active streak",
        loreDescription: "Resonating with deep visual tranquility. Amethyst Flow dissolves micro-spasms in the ciliary muscles, releasing deep-seated visual fatigue from persistent screen gaze."
    ),
    GemMilestone(
        id: "sapphire_aegis",
        displayName: "Sapphire Aegis",
        subtitle: "10 Exercises Done",
        color: Color(red: 0.22, green: 0.54, blue: 1.0),
        assetName: "gem_sapphire",
        fallbackSymbol: "shield.fill",
        unlockCondition: .exercisesCount(count: 10),
        unlockDescription: "Complete 10 vision sessions",
        loreDescription: "Forged through disciplined repetition. The Sapphire Aegis acts as a defensive prism, fortifying neural convergence and shielding your macula against digital dryness."
    ),
    GemMilestone(
        id: "emerald_horizon",
        displayName: "Emerald Horizon",
        subtitle: "7-Day Milestone",
        color: Color(red: 0.18, green: 0.86, blue: 0.52),
        assetName: "gem_emerald",
        fallbackSymbol: "leaf.fill",
        unlockCondition: .streak(days: 7),
        unlockDescription: "Achieve a full 7-day streak",
        loreDescription: "Attuned to the natural infinity horizon. Emerald Horizon celebrates adaptive ocular flexibility, proving that routine micro-rests have become an instinctive reflex."
    ),
    GemMilestone(
        id: "ruby_convergence",
        displayName: "Ruby Convergence",
        subtitle: "25 Exercises Done",
        color: Color(red: 1.0, green: 0.22, blue: 0.38),
        assetName: "gem_ruby",
        fallbackSymbol: "flame.fill",
        unlockCondition: .exercisesCount(count: 25),
        unlockDescription: "Complete 25 vision sessions",
        loreDescription: "Pulsing with high-contrast ocular vigor. Ruby Convergence denotes perfected binocular alignment, ensuring effortless transitions between close screens and distant sights."
    ),
    GemMilestone(
        id: "opal_luminary",
        displayName: "Opal Luminary",
        subtitle: "Screen Guardian",
        color: Color(red: 0.35, green: 0.88, blue: 0.94),
        assetName: "gem_opal",
        fallbackSymbol: "circle.hexagongrid.fill",
        unlockCondition: .screenTimeSaved(hours: 3),
        unlockDescription: "Shield 3h of screen strain",
        loreDescription: "Shimmering with ethereal prismatic tones. The Opal Luminary honors mindful digital moderation, redirecting reclaimed screen hours into deep restorative clarity."
    ),
    GemMilestone(
        id: "obsidian_sentinel",
        displayName: "Obsidian Sentinel",
        subtitle: "21-Day Mastery",
        color: Color(red: 0.62, green: 0.54, blue: 0.82),
        assetName: "gem_obsidian",
        fallbackSymbol: "rhombus.fill",
        unlockCondition: .streak(days: 21),
        unlockDescription: "Sustain a 21-day streak",
        loreDescription: "A crystalline fortress of neuromuscular resilience. Tempered over 21 days of unbroken habit, Obsidian Sentinel absorbs digital strain before fatigue can settle."
    ),
    GemMilestone(
        id: "lucid_crystal",
        displayName: "Lucid Prism",
        subtitle: "Vision Mastery",
        color: Color(red: 0.72, green: 0.94, blue: 1.0),
        assetName: "gem_crystal",
        fallbackSymbol: "diamond.fill",
        unlockCondition: .masterAll,
        unlockDescription: "50 exercises & 30-day streak",
        loreDescription: "The crown jewel of visual harmony. A diamond-clarity crystal encapsulating total mastery of accommodation, blink restoration, and peak digital resilience."
    )
]

// MARK: - Wreath Shape

private struct WreathRing: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.0), .white.opacity(0.2), .white.opacity(0.0)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: size, height: size)

            // Wreath dots (laurel-like)
            ForEach(0..<28, id: \.self) { i in
                let angle = Double(i) / 28.0 * 360.0
                let rads = angle * Double.pi / 180.0
                let r = Double(size / 2) - 4
                Circle()
                    .fill(Color.white.opacity(i % 2 == 0 ? 0.35 : 0.18))
                    .frame(width: i % 3 == 0 ? 5 : 3.5, height: i % 3 == 0 ? 5 : 3.5)
                    .offset(x: CGFloat(r * cos(rads)), y: CGFloat(r * sin(rads)))
            }

            // Arc text "• LUCID VISION •"
            Canvas { ctx, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = size.width / 2 - 16
                let text = "• LUCID VISION •"
                let chars = Array(text)
                let totalAngle: Double = 180
                let startAngle: Double = -270

                for (idx, char) in chars.enumerated() {
                    let fraction = Double(idx) / Double(chars.count - 1)
                    let angleDeg = startAngle + fraction * totalAngle
                    let angleRad = angleDeg * Double.pi / 180
                    let x = center.x + CGFloat(radius * cos(angleRad))
                    let y = center.y + CGFloat(radius * sin(angleRad))

                    let resolved = ctx.resolve(
                        Text(String(char))
                            .font(Typography.caption2(weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                    )
                    ctx.draw(resolved, at: CGPoint(x: x, y: y))
                }
            }
            .frame(width: size, height: size)
        }
    }
}

// MARK: - Stat Chip

private struct StatChip: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    var subtitle: String? = nil
    var isLoading: Bool = false
    var onInfoTap: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(Typography.callout(weight: .semibold))
                    .foregroundStyle(color)
                    .symbolEffect(.pulse, options: .repeating, isActive: isLoading)
            }

            Text(value)
                .font(Typography.hero(size: 24, weight: .bold, design: .rounded, relativeTo: .title))
                .foregroundStyle(.white)
                .contentTransition(.numericText())

            Text(label)
                .font(Typography.caption2(weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .kerning(0.8)
                .textCase(.uppercase)

            if let subtitle {
                Text(subtitle)
                    .font(Typography.caption2(design: .rounded))
                    .foregroundStyle(color.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 10)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.65))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                }
        }
        .overlay(alignment: .topTrailing) {
            if onInfoTap != nil {
                HStack(spacing: 0) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.45))
                }
                .padding(10)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onTapGesture {
            if let onInfoTap {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onInfoTap()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint(onInfoTap != nil ? "Double tap to learn what this metric means." : "")
    }
}

// MARK: - Gem Card

private struct GemCard: View {
    let gem: GemMilestone
    let isUnlocked: Bool
    let progressCurrent: Int
    let progressTotal: Int

    @State private var isFloating = false

    var body: some View {
        VStack(spacing: 10) {
            // Gem Display Chamber
            ZStack {
                // Ambient Radial Caustic Glow for unlocked gems
                if isUnlocked {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [gem.color.opacity(0.42), gem.color.opacity(0.12), .clear],
                                center: .center,
                                startRadius: 2,
                                endRadius: 44
                            )
                        )
                        .frame(width: 88, height: 88)
                        .blur(radius: 6)

                    // Ground reflection / pedestal shadow
                    Ellipse()
                        .fill(gem.color.opacity(0.28))
                        .frame(width: 44, height: 10)
                        .blur(radius: 4)
                        .offset(y: 34)
                        .scaleEffect(isFloating ? 0.85 : 1.15)
                } else {
                    // Subtle locked pedestal
                    Ellipse()
                        .fill(Color.white.opacity(0.04))
                        .frame(width: 40, height: 8)
                        .offset(y: 34)
                }

                // Gem Asset Image or Fallback
                if UIImage(named: gem.assetName) != nil {
                    Image(gem.assetName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 62, height: 62)
                        .saturation(isUnlocked ? 1.05 : 0.0)
                        .contrast(isUnlocked ? 1.05 : 0.8)
                        .opacity(isUnlocked ? 1.0 : 0.28)
                        .shadow(color: isUnlocked ? gem.color.opacity(0.7) : .clear, radius: 10, y: 2)
                        .offset(y: isUnlocked && isFloating ? -4 : 2)
                } else {
                    // Fallback procedural icon
                    ZStack {
                        RoundedPolygon(sides: 6, cornerRadius: 12)
                            .fill(isUnlocked ? gem.color.opacity(0.22) : Color.white.opacity(0.04))
                            .frame(width: 58, height: 58)

                        RoundedPolygon(sides: 6, cornerRadius: 12)
                            .stroke(isUnlocked ? gem.color.opacity(0.4) : .white.opacity(0.1), lineWidth: 1.5)
                            .frame(width: 58, height: 58)

                        Image(systemName: gem.fallbackSymbol)
                            .font(Typography.title2(weight: .bold))
                            .foregroundStyle(isUnlocked ? gem.color : .white.opacity(0.35))
                    }
                    .offset(y: isUnlocked && isFloating ? -3 : 3)
                }

                // Locked overlay badge if not unlocked
                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.55))
                        .padding(5)
                        .background(Circle().fill(Color.black.opacity(0.65)))
                        .offset(x: 24, y: -24)
                }
            }
            .frame(height: 76)
            .padding(.top, 4)

            // Name
            Text(gem.displayName)
                .font(Typography.footnote(weight: .bold, design: .rounded))
                .foregroundStyle(isUnlocked ? .white : .white.opacity(0.55))
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            // Status or Progress
            if isUnlocked {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 9, weight: .bold))
                    Text(statusLabel)
                        .font(Typography.caption2(weight: .bold, design: .rounded))
                }
                .foregroundStyle(gem.color)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(gem.color.opacity(0.16))
                        .overlay(Capsule().strokeBorder(gem.color.opacity(0.38), lineWidth: 1))
                )
            } else {
                VStack(spacing: 4) {
                    // Sleek progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.1))
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [gem.color.opacity(0.7), gem.color],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(3, geo.size.width * CGFloat(progressCurrent) / CGFloat(max(1, progressTotal))))
                        }
                    }
                    .frame(height: 3.5)

                    HStack(spacing: 2) {
                        Text("\(progressCurrent)/\(progressTotal)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(gem.color.opacity(0.85))

                        Spacer()

                        Text(gem.subtitle)
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                            .lineLimit(1)
                    }
                }
                .frame(height: 24)
                .padding(.horizontal, 4)
            }
        }
        .frame(width: 136, height: 168)
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    isUnlocked
                        ? Color(red: 0.08, green: 0.10, blue: 0.18).opacity(0.75)
                        : Color(red: 0.06, green: 0.07, blue: 0.11).opacity(0.65)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(
                            isUnlocked
                                ? LinearGradient(
                                    colors: [gem.color.opacity(0.65), gem.color.opacity(0.2), .white.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [.white.opacity(0.08), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                            lineWidth: 1
                        )
                }
        }
        .onAppear {
            if isUnlocked {
                withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                    isFloating = true
                }
            }
        }
    }

    private var statusLabel: String {
        switch gem.unlockCondition {
        case .firstExercise:
            return "Active"
        case .streak(let days):
            return "\(days)d Streak"
        case .exercisesCount(let count):
            return "\(count) Done"
        case .screenTimeSaved(let hours):
            return "\(Int(hours))h Saved"
        case .masterAll:
            return "Master"
        }
    }
}

// MARK: - Gem Detail Sheet

private struct GemDetailSheet: View {
    let gem: GemMilestone
    let isUnlocked: Bool
    let progressCurrent: Int
    let progressTotal: Int

    @Environment(\.dismiss) private var dismiss
    @State private var isFloating = false
    @State private var haloRotate = false

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.05, blue: 0.09).ignoresSafeArea()

            // Ambient Gem Glow from top
            RadialGradient(
                colors: [gem.color.opacity(0.35), gem.color.opacity(0.08), .clear],
                center: .init(x: 0.5, y: 0.22),
                startRadius: 20,
                endRadius: 360
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    // Drag handle
                    Capsule()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 38, height: 4)
                        .padding(.top, 12)

                    // Majestic Gem Hero Stage
                    ZStack {
                        // Outer rotating halo ring
                        Circle()
                            .strokeBorder(
                                AngularGradient(
                                    gradient: Gradient(colors: [gem.color.opacity(0.4), .clear, gem.color.opacity(0.6), .clear]),
                                    center: .center
                                ),
                                lineWidth: 1.5
                            )
                            .frame(width: 190, height: 190)
                            .rotationEffect(.degrees(haloRotate ? 360 : 0))

                        // Inner atmospheric bloom
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [gem.color.opacity(isUnlocked ? 0.45 : 0.15), .clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 85
                                )
                            )
                            .frame(width: 170, height: 170)
                            .blur(radius: 12)

                        // Pedestal Reflection
                        Ellipse()
                            .fill(gem.color.opacity(isUnlocked ? 0.35 : 0.08))
                            .frame(width: 90, height: 18)
                            .blur(radius: 6)
                            .offset(y: 72)
                            .scaleEffect(isFloating ? 0.88 : 1.12)

                        // Real Gemstone Asset or Fallback
                        if UIImage(named: gem.assetName) != nil {
                            Image(gem.assetName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 120, height: 120)
                                .saturation(isUnlocked ? 1.08 : 0.0)
                                .contrast(isUnlocked ? 1.05 : 0.75)
                                .opacity(isUnlocked ? 1.0 : 0.35)
                                .shadow(color: isUnlocked ? gem.color.opacity(0.8) : .clear, radius: 24, y: 4)
                                .offset(y: isFloating ? -8 : 6)
                        } else {
                            ZStack {
                                RoundedPolygon(sides: 6, cornerRadius: 20)
                                    .fill(isUnlocked ? gem.color.opacity(0.25) : Color.white.opacity(0.05))
                                    .frame(width: 110, height: 110)

                                RoundedPolygon(sides: 6, cornerRadius: 20)
                                    .stroke(isUnlocked ? gem.color : .white.opacity(0.2), lineWidth: 2)
                                    .frame(width: 110, height: 110)

                                Image(systemName: gem.fallbackSymbol)
                                    .font(Typography.hero(size: 48, weight: .bold, relativeTo: .title))
                                    .foregroundStyle(isUnlocked ? gem.color : .white.opacity(0.3))
                            }
                            .offset(y: isFloating ? -6 : 6)
                        }

                        // Locked center emblem if not unlocked
                        if !isUnlocked {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 44, height: 44)
                                    .overlay(Circle().strokeBorder(.white.opacity(0.2), lineWidth: 1))

                                Image(systemName: "lock.fill")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                    }
                    .frame(height: 200)
                    .padding(.top, 6)

                    // Title & Subtitle
                    VStack(spacing: 6) {
                        Text(gem.displayName)
                            .font(Typography.hero(size: 28, weight: .bold, design: .rounded, relativeTo: .title))
                            .foregroundStyle(.white)

                        HStack(spacing: 6) {
                            Circle()
                                .fill(gem.color)
                                .frame(width: 8, height: 8)

                            Text(gem.subtitle)
                                .font(Typography.subheadline(weight: .semibold, design: .rounded))
                                .foregroundStyle(gem.color)
                        }
                    }

                    // Status & Progression Card
                    VStack(spacing: 12) {
                        if isUnlocked {
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(gem.color)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("UNLOCKED & SHINING")
                                        .font(Typography.caption2(weight: .bold, design: .rounded))
                                        .foregroundStyle(gem.color)
                                        .kerning(1)

                                    Text(gem.unlockDescription)
                                        .font(Typography.subheadline(weight: .medium, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.9))
                                }

                                Spacer()
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("FORGE PROGRESS")
                                        .font(Typography.caption2(weight: .bold, design: .rounded))
                                        .foregroundStyle(gem.color)
                                        .kerning(1)

                                    Spacer()

                                    Text("\(progressCurrent) / \(progressTotal)")
                                        .font(Typography.subheadline(weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                }

                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Color.white.opacity(0.12))
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [gem.color.opacity(0.7), gem.color],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: max(4, geo.size.width * CGFloat(progressCurrent) / CGFloat(max(1, progressTotal))))
                                    }
                                }
                                .frame(height: 7)

                                HStack(spacing: 6) {
                                    Image(systemName: "target")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(gem.color)
                                    Text(gem.unlockDescription)
                                        .font(Typography.caption(weight: .medium, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(red: 0.08, green: 0.10, blue: 0.18).opacity(0.8))
                            .overlay {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .strokeBorder(
                                        isUnlocked ? gem.color.opacity(0.35) : Color.white.opacity(0.1),
                                        lineWidth: 1
                                    )
                            }
                    }
                    .padding(.horizontal, 24)

                    // Lore Description Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(gem.color)
                            Text("ARCHIVE CODEX")
                                .font(Typography.caption2(weight: .bold, design: .rounded))
                                .foregroundStyle(gem.color)
                                .kerning(1.2)
                        }

                        Text(gem.loreDescription)
                            .font(Typography.subheadline(design: .rounded))
                            .foregroundStyle(.white.opacity(0.88))
                            .lineSpacing(4)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(.ultraThinMaterial.opacity(0.65))
                            .overlay {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                            }
                    }
                    .padding(.horizontal, 24)

                    // Close Button
                    Button {
                        dismiss()
                    } label: {
                        Text("Close")
                            .font(Typography.headline(weight: .bold, design: .rounded))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(gem.color)
                                    .shadow(color: gem.color.opacity(0.4), radius: 12, y: 4)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)
                    .padding(.top, 6)
                    .padding(.bottom, 24)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                isFloating = true
            }
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                haloRotate = true
            }
        }
    }
}

// MARK: - Profile Stat Info & Detail Sheet

private struct ProfileStatInfo: Identifiable {
    var id: String { title }
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let currentValue: String
    let laymanSummary: String
    let whyItMatters: String
    let howToImprove: String
}

private struct ProfileStatDetailSheet: View {
    let info: ProfileStatInfo
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.08, blue: 0.14).ignoresSafeArea()

            RadialGradient(
                colors: [info.color.opacity(0.18), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 280
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Drag handle
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        // Header
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(info.color.opacity(0.15))
                                    .frame(width: 52, height: 52)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .strokeBorder(info.color.opacity(0.35), lineWidth: 1)
                                    )

                                Image(systemName: info.icon)
                                    .font(Typography.title2(weight: .bold))
                                    .foregroundStyle(info.color)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(info.title)
                                    .font(Typography.title3(weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)

                                HStack(spacing: 6) {
                                    Text(info.subtitle)
                                        .font(Typography.caption(weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.6))

                                    Text("•")
                                        .foregroundStyle(.white.opacity(0.3))

                                    Text(info.currentValue)
                                        .font(Typography.caption(weight: .bold, design: .rounded))
                                        .foregroundStyle(info.color)
                                }
                            }

                            Spacer()
                        }
                        .padding(.top, 14)

                        // 1. In Layman's Terms
                        glassCard(
                            icon: "info.circle.fill",
                            iconColor: info.color,
                            title: "What is this?",
                            description: info.laymanSummary
                        )

                        // 2. Clinical Significance
                        glassCard(
                            icon: "heart.text.square.fill",
                            iconColor: Palette.ember,
                            title: "Why does it matter?",
                            description: info.whyItMatters
                        )

                        // 3. Actionable Protocol
                        glassCard(
                            icon: "arrow.up.forward.circle.fill",
                            iconColor: .green,
                            title: "How do I improve it?",
                            description: info.howToImprove
                        )

                        Spacer().frame(height: 24)
                    }
                    .padding(.horizontal, 22)
                }
            }
        }
        .presentationDetents([.fraction(0.75), .large])
        .presentationDragIndicator(.hidden)
    }

    private func glassCard(icon: String, iconColor: Color, title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(Typography.subheadline(weight: .semibold))
                    .foregroundStyle(iconColor)

                Text(title)
                    .font(Typography.headline(weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Text(description)
                .font(Typography.callout(design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.5))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                }
        }
    }
}

// MARK: - Profile View

public struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var supabase = SupabaseService.shared
    @State private var scoreEngine: LucidScoreEngine

    // Navigation & Sheet states
    @State private var showSettings = false
    @State private var selectedGem: GemMilestone? = nil
    @State private var selectedStatInfo: ProfileStatInfo? = nil
    
    // Loaded Stats
    @State private var exercisesCompleted: Int
    @State private var dayStreak: Int
    @State private var isLoading: Bool = false
    
    // Animation triggers
    @State private var avatarAppeared = false
    @State private var statsAppeared = false
    @State private var gemsAppeared = false

    private let customProfile: UserProfile?
    private let isPreview: Bool

    private var activeProfile: UserProfile? {
        customProfile ?? supabase.currentProfile
    }

    private var profileName: String {
        let name = activeProfile?.name ?? ""
        return name.isEmpty ? "Visionary" : name
    }

    private var screenTimeHours: Double {
        activeProfile?.estimatedDailyScreenTimeHours ?? 6.5
    }

    private var timeSavedHours: Double {
        let baseline = screenTimeHours
        let saved = Double(exercisesCompleted) * 0.35 + Double(dayStreak) * 0.2
        return max(0.5, min(baseline, saved))
    }

    private var focusHours: Int {
        exercisesCompleted * 2
    }

    public init(
        scoreEngine: LucidScoreEngine = .shared,
        exercisesCompleted: Int? = nil,
        dayStreak: Int? = nil,
        userProfile: UserProfile? = nil
    ) {
        _scoreEngine = State(initialValue: scoreEngine)
        let hasCustomStats = exercisesCompleted != nil || dayStreak != nil || userProfile != nil
        self.isPreview = hasCustomStats
        _exercisesCompleted = State(initialValue: exercisesCompleted ?? StreakManager.shared.totalExercisesCompleted)
        _dayStreak = State(initialValue: dayStreak ?? StreakManager.shared.currentStreak)
        self.customProfile = userProfile
    }

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.black.ignoresSafeArea()

                // Ambient glow backgrounds
                ZStack {
                    RadialGradient(
                        colors: [Color.white.opacity(0.04), .clear],
                        center: .top,
                        startRadius: 20,
                        endRadius: 400
                    )
                    .ignoresSafeArea()

                    RadialGradient(
                        colors: [Color.purple.opacity(0.04), .clear],
                        center: .init(x: 0.5, y: 0.7),
                        startRadius: 0,
                        endRadius: 320
                    )
                    .ignoresSafeArea()
                }

                // Main Scrollable Content with Homepage Cave Background
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 72) // Space for top header bar

                        // ── HERO SECTION ────────────────────────
                        heroSection

                        // ── PERFORMANCE STATS MATRIX ───────────
                        statsMatrixSection

                        // ── GEMSTONES & ACHIEVEMENTS ───────────
                        gemstonesSection

                        // ── PRESCRIPTION & CLINICAL METRICS ───
                        prescriptionSection

                        // ── DIGITAL WELLBEING & HABITS ────────
                        screenHabitsSection

                        Spacer().frame(height: 100)
                    }
                    .background(alignment: .top) {
                        CaveBackground().frame(height: 620)
                    }
                }
                .scrollIndicators(.hidden)
                .ignoresSafeArea(edges: .top)

                // Top Header Fade Gradient Overlay (matching HomeView)
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: Color.black.opacity(0.92), location: 0.55),
                        .init(color: Color.black.opacity(0), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
                .allowsHitTesting(false)
                .ignoresSafeArea(edges: .top)

                // ── TOP NAVIGATION BAR ─────────────────────
                topNavigationBar
            }
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showSettings) {
                SettingsView(onLogout: {
                    dismiss()
                })
            }
            .sheet(item: $selectedGem) { gem in
                let unlocked = gem.unlockCondition.isUnlocked(
                    exercises: exercisesCompleted,
                    streak: dayStreak,
                    screenTimeSaved: timeSavedHours
                )
                let prog = gem.unlockCondition.progress(
                    exercises: exercisesCompleted,
                    streak: dayStreak,
                    screenTimeSaved: timeSavedHours
                )
                GemDetailSheet(
                    gem: gem,
                    isUnlocked: unlocked,
                    progressCurrent: prog?.current ?? 0,
                    progressTotal: prog?.total ?? 1
                )
            }
            .onAppear {
                loadStats()
                withAnimation { avatarAppeared = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation { statsAppeared = true }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation { gemsAppeared = true }
                }
            }
        }
    }

    // MARK: - Top Navigation Bar
    private var topNavigationBar: some View {
        HStack {
            // Real Back Button
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                dismiss()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.left")
                        .font(Typography.footnote(weight: .semibold))
                    Text("Back")
                        .font(Typography.subheadline(weight: .medium, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .glassEffect(.clear, in: .capsule)
                        .overlay {
                            Capsule().strokeBorder(.white.opacity(0.14), lineWidth: 1)
                        }
                }
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .accessibilityLabel("Go back")

            Spacer()

            Text("Profile")
                .font(Typography.headline(weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            // Real Settings Button
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showSettings = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "gearshape.fill")
                        .font(Typography.footnote(weight: .semibold))
                    Text("Settings")
                        .font(Typography.subheadline(weight: .medium, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .glassEffect(.clear, in: .capsule)
                        .overlay {
                            Capsule().strokeBorder(.white.opacity(0.14), lineWidth: 1)
                        }
                }
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .accessibilityLabel("Open settings")
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 0) {
            // Wreath + Avatar + Crown Gemstone
            ZStack {
                WreathRing(size: 160)
                    .scaleEffect(avatarAppeared ? 1 : 0.7)
                    .opacity(avatarAppeared ? 1 : 0)
                    .animation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.1), value: avatarAppeared)

                ZStack {
                    RoundedPolygon(sides: 6, cornerRadius: 14)
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 82, height: 82)

                    RoundedPolygon(sides: 6, cornerRadius: 14)
                        .stroke(.white.opacity(0.18), lineWidth: 1.5)
                        .frame(width: 82, height: 82)

                    Image(systemName: "person.fill")
                        .font(Typography.hero(size: 34, relativeTo: .title))
                        .foregroundStyle(.white)
                }
                .scaleEffect(avatarAppeared ? 1 : 0.4)
                .opacity(avatarAppeared ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: avatarAppeared)

                // Crown Milestone Gemstone Badge on Avatar (Highest Unlocked)
                if let highestGem = highestUnlockedGem {
                    if UIImage(named: highestGem.assetName) != nil {
                        Image(highestGem.assetName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 28, height: 28)
                            .shadow(color: highestGem.color.opacity(0.8), radius: 6)
                            .offset(x: 32, y: 30)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .padding(.bottom, 16)

            // User Name
            Text(profileName)
                .font(Typography.hero(size: 26, weight: .bold, design: .rounded, relativeTo: .title2))
                .foregroundStyle(.white)
                .scaleEffect(avatarAppeared ? 1 : 0.85)
                .opacity(avatarAppeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: avatarAppeared)

            // Email or Badge
            HStack(spacing: 6) {
                if let email = activeProfile?.email, !email.isEmpty {
                    Image(systemName: "checkmark.seal.fill")
                        .font(Typography.caption2())
                        .foregroundStyle(.white.opacity(0.7))

                    Text(email)
                        .font(Typography.footnote(weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                } else {
                    Text("Lucid Vision Guardian")
                        .font(Typography.caption(weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(.top, 4)
            .opacity(avatarAppeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.4), value: avatarAppeared)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 24)
    }

    // MARK: - Stats Matrix Section
    private var statsMatrixSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                StatChip(
                    icon: "chart.bar.fill",
                    value: "\(scoreEngine.overallScore)%",
                    label: "Lucid Score",
                    color: .blue,
                    subtitle: "Visual Vitality",
                    onInfoTap: {
                        selectedStatInfo = ProfileStatInfo(
                            title: "Visual Vitality",
                            subtitle: "Lucid Score",
                            icon: "chart.bar.fill",
                            color: .blue,
                            currentValue: "\(scoreEngine.overallScore)%",
                            laymanSummary: "Your overall eye health score on a scale from 0% to 100%. It measures how well you are balancing screen time with regular eye rests, daily vision workouts, and visual acuity check-ins.",
                            whyItMatters: "Staring at screens continuously puts your eye muscles under constant strain and cuts your blink rate by more than half. A high Vitality score means your eyes are getting enough rest and movement to ward off headaches, dryness, and digital blurriness.",
                            howToImprove: "Complete your daily eye workouts, look away into the distance for 20 seconds during long screen hours, and keep your care streak alive."
                        )
                    }
                )

                StatChip(
                    icon: "flame.fill",
                    value: "\(dayStreak)",
                    label: "Day Streak",
                    color: .orange,
                    subtitle: "Habit Equity",
                    onInfoTap: {
                        selectedStatInfo = ProfileStatInfo(
                            title: "Habit Equity",
                            subtitle: "Day Streak",
                            icon: "flame.fill",
                            color: .orange,
                            currentValue: "\(dayStreak) \(dayStreak == 1 ? "Day" : "Days")",
                            laymanSummary: "Your active care streak — the number of consecutive days you have protected your vision by finishing your daily exercises or taking scheduled breaks.",
                            whyItMatters: "Eye fatigue compounds silently day after day. Spending just 2 to 3 minutes on eye care every single day builds lasting resilience (equity) in your visual system, which is far more effective than doing one long session once in a while.",
                            howToImprove: "Finish at least one recommended routine each day before midnight to keep your streak glowing and protect your habit equity."
                        )
                    }
                )
            }

            HStack(spacing: 10) {
                StatChip(
                    icon: "hourglass",
                    value: "\(focusHours)h",
                    label: "Focus Time",
                    color: .teal,
                    subtitle: "Restored Rest",
                    onInfoTap: {
                        selectedStatInfo = ProfileStatInfo(
                            title: "Restored Rest",
                            subtitle: "Focus Time",
                            icon: "hourglass",
                            color: .teal,
                            currentValue: "\(focusHours)h",
                            laymanSummary: "The cumulative hours of restorative relief your eyes have earned back through mindful focus breaks and guided training routines.",
                            whyItMatters: "When looking at screens up close, the internal focusing muscles inside your eyes are clenched in continuous tension. Restored Rest represents the high-value break time where your eyes were relaxed, allowed to focus far away, and rehydrated with natural tears.",
                            howToImprove: "Follow the 20-20-20 rule (every 20 minutes, look 20 feet away for 20 seconds) and run your focus shifting drills to accumulate more rest time."
                        )
                    }
                )

                StatChip(
                    icon: "checkmark.circle.fill",
                    value: "\(exercisesCompleted)",
                    label: "Exercises",
                    color: .green,
                    subtitle: "Sessions Done",
                    onInfoTap: {
                        selectedStatInfo = ProfileStatInfo(
                            title: "Sessions Done",
                            subtitle: "Completed Exercises",
                            icon: "checkmark.circle.fill",
                            color: .green,
                            currentValue: "\(exercisesCompleted) \(exercisesCompleted == 1 ? "Session" : "Sessions")",
                            laymanSummary: "The total count of guided eye exercise workouts you have finished, including blink training, near-far focus shifts, and eye tracking loops.",
                            whyItMatters: "Your eyes are steered by 6 delicate muscles and focused by an internal lens muscle. Just like stretching your legs after sitting all day, these workouts keep your eye muscles agile, coordinated, and strain-free.",
                            howToImprove: "Aim for 2 quick sessions each day — one in the morning to wake up your eyes, and one in the afternoon to release screen tension."
                        )
                    }
                )
            }
        }
        .padding(.horizontal, 18)
        .offset(y: statsAppeared ? 0 : 25)
        .opacity(statsAppeared ? 1 : 0)
        .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.15), value: statsAppeared)
        .padding(.bottom, 28)
        .sheet(item: $selectedStatInfo) { info in
            ProfileStatDetailSheet(info: info)
        }
    }

    // MARK: - Gemstones Section
    private var gemstonesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Palette.amber)
                        .font(Typography.headline())
                    Text("Milestone Gemstones")
                        .font(Typography.title3(weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                Spacer()

                Text("\(unlockedCount)/\(gemCatalog.count) Unlocked")
                    .font(Typography.subheadline(weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 5)
                    .background {
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay {
                                Capsule().strokeBorder(Palette.amber.opacity(0.35), lineWidth: 1)
                            }
                    }
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    Spacer().frame(width: 6)

                    ForEach(Array(gemCatalog.enumerated()), id: \.element.id) { idx, gem in
                        let unlocked = gem.unlockCondition.isUnlocked(
                            exercises: exercisesCompleted,
                            streak: dayStreak,
                            screenTimeSaved: timeSavedHours
                        )
                        let prog = gem.unlockCondition.progress(
                            exercises: exercisesCompleted,
                            streak: dayStreak,
                            screenTimeSaved: timeSavedHours
                        )

                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            selectedGem = gem
                        } label: {
                            GemCard(
                                gem: gem,
                                isUnlocked: unlocked,
                                progressCurrent: prog?.current ?? 0,
                                progressTotal: prog?.total ?? 1
                            )
                        }
                        .buttonStyle(.plain)
                        .offset(y: gemsAppeared ? 0 : 30)
                        .opacity(gemsAppeared ? 1 : 0)
                        .animation(
                            .spring(response: 0.55, dampingFraction: 0.8).delay(0.06 * Double(idx)),
                            value: gemsAppeared
                        )
                    }

                    Spacer().frame(width: 6)
                }
                .padding(.vertical, 6)
            }
        }
        .padding(.bottom, 28)
    }

    // MARK: - Prescription Section
    private var prescriptionSection: some View {
        Group {
            if let profile = activeProfile {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "eyeglasses")
                            .foregroundStyle(.white.opacity(0.85))
                            .font(Typography.headline())
                        Text("Vision & Prescription")
                            .font(Typography.headline(weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Spacer()
                        Text(profile.hasGlassesOrContacts ? "Corrective Lenses" : "Unaided")
                            .font(Typography.caption2(weight: .bold, design: .rounded))
                            .foregroundStyle(.teal)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background {
                                Capsule().fill(.teal.opacity(0.14))
                            }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)

                    Divider().background(.white.opacity(0.07))

                    // Left & Right eye display pods
                    HStack(spacing: 12) {
                        // Left Eye
                        VStack(alignment: .leading, spacing: 6) {
                            Text("LEFT EYE (OS)")
                                .font(Typography.caption2(weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.45))
                                .kerning(0.8)

                            Text(String(format: "%.2f D", profile.leftEyePower))
                                .font(Typography.hero(size: 22, weight: .bold, design: .rounded, relativeTo: .title3))
                                .foregroundStyle(.white)

                            Text(profile.leftEyePower < 0 ? "Myopic correction" : (profile.leftEyePower > 0 ? "Hyperopic correction" : "Plano / Normal"))
                                .font(Typography.caption2(design: .rounded))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.03))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 14).strokeBorder(.white.opacity(0.06), lineWidth: 1)
                                }
                        }

                        // Right Eye
                        VStack(alignment: .leading, spacing: 6) {
                            Text("RIGHT EYE (OD)")
                                .font(Typography.caption2(weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.45))
                                .kerning(0.8)

                            Text(String(format: "%.2f D", profile.rightEyePower))
                                .font(Typography.hero(size: 22, weight: .bold, design: .rounded, relativeTo: .title3))
                                .foregroundStyle(.white)

                            Text(profile.rightEyePower < 0 ? "Myopic correction" : (profile.rightEyePower > 0 ? "Hyperopic correction" : "Plano / Normal"))
                                .font(Typography.caption2(design: .rounded))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.03))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 14).strokeBorder(.white.opacity(0.06), lineWidth: 1)
                                }
                        }
                    }
                    .padding(.horizontal, 18)

                    // Primary Focus Activity
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Primary Screen Task")
                                .font(Typography.footnote(weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.55))
                            Text(profile.primaryActivity.isEmpty ? "General Digital Work" : profile.primaryActivity)
                                .font(Typography.subheadline(weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        Image(systemName: activityIcon(for: profile.primaryActivity))
                            .foregroundStyle(.white.opacity(0.3))
                            .font(.title3)
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 16)
                }
                .background {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(0.6))
                        .overlay {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .strokeBorder(.white.opacity(0.07), lineWidth: 1)
                        }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Screen Habits Section
    private var screenHabitsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "eye.fill")
                    .foregroundStyle(.white.opacity(0.85))
                    .font(Typography.headline())
                Text("Digital Wellbeing & Habits")
                    .font(Typography.headline(weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)

            Divider().background(.white.opacity(0.07))

            ScreenTimeRow(
                label: "Target Screen Limit",
                value: String(format: "%.1f hrs", screenTimeHours),
                icon: "timer",
                color: .blue
            )

            Divider().background(.white.opacity(0.05)).padding(.horizontal, 18)

            ScreenTimeRow(
                label: "Time Saved from Strain",
                value: String(format: "%.1f hrs", timeSavedHours),
                icon: "clock.badge.checkmark",
                color: .teal
            )

            if let peakTime = activeProfile?.peakFatigueTime, !peakTime.isEmpty {
                Divider().background(.white.opacity(0.05)).padding(.horizontal, 18)
                ScreenTimeRow(
                    label: "Peak Eye Strain",
                    value: peakTime,
                    icon: "moon.stars.fill",
                    color: .indigo
                )
            }

            Spacer().frame(height: 8)
        }
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.6))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(.white.opacity(0.07), lineWidth: 1)
                }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 24)
    }

    // MARK: - Logic Helpers
    private func activityIcon(for activity: String) -> String {
        switch activity {
        case "Coding & Reading": return "laptopcomputer"
        case "Video & Gaming": return "play.tv.fill"
        case "Office & Writing": return "doc.text.fill"
        case "Social & Mobile": return "iphone"
        default: return "laptopcomputer"
        }
    }

    private var unlockedCount: Int {
        gemCatalog.filter {
            $0.unlockCondition.isUnlocked(exercises: exercisesCompleted, streak: dayStreak, screenTimeSaved: timeSavedHours)
        }.count
    }

    private var highestUnlockedGem: GemMilestone? {
        gemCatalog.reversed().first {
            $0.unlockCondition.isUnlocked(exercises: exercisesCompleted, streak: dayStreak, screenTimeSaved: timeSavedHours)
        }
    }

    private func loadStats() {
        guard !isPreview else { return }
        StreakManager.shared.refreshStreakState()
        exercisesCompleted = StreakManager.shared.totalExercisesCompleted
        dayStreak = StreakManager.shared.currentStreak
        isLoading = false

        Task {
            _ = await supabase.syncProfileWithRemote()
        }
    }
}

// MARK: - Screen Time Row Helper

private struct ScreenTimeRow: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(Typography.caption(weight: .semibold))
                    .foregroundStyle(color)
            }

            Text(label)
                .font(Typography.subheadline(weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))

            Spacer()

            Text(value)
                .font(Typography.subheadline(weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 2)
    }
}

#Preview("Achieved Milestones & Scores") {
    ProfileView(
        scoreEngine: .preview(rest: 85, exercise: 80, test: 87, isCalibrated: true),
        exercisesCompleted: 14,
        dayStreak: 7,
        userProfile: UserProfile(
            name: "Alex Rivera",
            email: "alex.rivera@example.com",
            leftEyePower: -1.75,
            rightEyePower: -2.00,
            hasGlassesOrContacts: true,
            estimatedDailyScreenTimeHours: 7.5,
            primaryActivity: "Coding & Reading",
            peakFatigueTime: "Late Day (5–8 PM)"
        )
    )
}

#Preview("New User (Default)") {
    ProfileView()
}
