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
        id: "spark",
        displayName: "First Spark",
        subtitle: "First Session Completed",
        color: Palette.amber,
        assetName: "spark_gem",
        fallbackSymbol: "sparkles",
        unlockCondition: .firstExercise,
        unlockDescription: "Complete 1 vision exercise",
        loreDescription: "The first ignition of ocular endurance. A warm reminder that every visual transformation begins with a single intentional blink."
    ),
    GemMilestone(
        id: "amethyst_clarity",
        displayName: "Amethyst Flow",
        subtitle: "3-Day Consistency",
        color: .purple,
        assetName: "amethyst_gem",
        fallbackSymbol: "rhombus.fill",
        unlockCondition: .streak(days: 3),
        unlockDescription: "Maintain a 3-day active streak",
        loreDescription: "Resonating at the frequency of visual calm. Amethyst stabilizes neuromuscular tension around the orbital ring."
    ),
    GemMilestone(
        id: "sapphire_shield",
        displayName: "Sapphire Aegis",
        subtitle: "10 Exercises Done",
        color: .blue,
        assetName: "sapphire_gem",
        fallbackSymbol: "shield.fill",
        unlockCondition: .exercisesCount(count: 10),
        unlockDescription: "Complete 10 vision training sessions",
        loreDescription: "Forged in focused repetition. The Sapphire Aegis shields your macula from visual fatigue and digital dryness."
    ),
    GemMilestone(
        id: "emerald_focus",
        displayName: "Emerald Horizon",
        subtitle: "7-Day Milestone",
        color: .green,
        assetName: "emerald_gem",
        fallbackSymbol: "diamond.fill",
        unlockCondition: .streak(days: 7),
        unlockDescription: "Achieve a full 7-day care streak",
        loreDescription: "The emerald crystal is attuned to natural focal distance. It marks a brain adapted to rhythmic micro-recovery."
    ),
    GemMilestone(
        id: "ruby_vitality",
        displayName: "Ruby Convergence",
        subtitle: "25 Exercises Done",
        color: .red,
        assetName: "ruby_gem",
        fallbackSymbol: "hexagon.fill",
        unlockCondition: .exercisesCount(count: 25),
        unlockDescription: "Complete 25 vision sessions",
        loreDescription: "Ciliary muscles functioning in pure synchrony. The ruby core pulsates with peak ocular endurance."
    ),
    GemMilestone(
        id: "diamond_mastery",
        displayName: "Lucid Prism",
        subtitle: "Vision Mastery",
        color: .cyan,
        assetName: "diamond_gem",
        fallbackSymbol: "seal.fill",
        unlockCondition: .masterAll,
        unlockDescription: "50 exercises & 30-day streak",
        loreDescription: "The ultimate crystal of visual equilibrium. Total mastery of accommodation, blink restoration, and digital resilience."
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
            ZStack {
                // Background radial glow for unlocked gems
                if isUnlocked {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [gem.color.opacity(0.35), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 36
                            )
                        )
                        .frame(width: 72, height: 72)
                        .blur(radius: 6)
                }

                // Gem Asset or Rendered Polygon
                if UIImage(named: gem.assetName) != nil {
                    Image(gem.assetName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 52, height: 52)
                        .saturation(isUnlocked ? 1.0 : 0.0)
                        .opacity(isUnlocked ? 1.0 : 0.35)
                        .shadow(color: isUnlocked ? gem.color.opacity(0.6) : .clear, radius: 8)
                } else {
                    // Fallback procedural icon
                    ZStack {
                        RoundedPolygon(sides: 6, cornerRadius: 10)
                            .fill(isUnlocked ? gem.color.opacity(0.2) : Color.white.opacity(0.04))
                            .frame(width: 54, height: 54)

                        RoundedPolygon(sides: 6, cornerRadius: 10)
                            .stroke(.white.opacity(isUnlocked ? 0.25 : 0.1), lineWidth: 1.5)
                            .frame(width: 54, height: 54)

                        Image(systemName: gem.fallbackSymbol)
                            .font(Typography.title2(weight: .bold))
                            .foregroundStyle(isUnlocked ? gem.color : .white.opacity(0.35))
                    }
                    .offset(y: isFloating ? -3 : 3)
                    .onAppear {
                        if isUnlocked {
                            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                                isFloating.toggle()
                            }
                        }
                    }
                }
            }
            .frame(height: 64)

            Text(gem.displayName)
                .font(Typography.footnote(weight: .semibold, design: .rounded))
                .foregroundStyle(isUnlocked ? .white : .white.opacity(0.45))
                .lineLimit(1)

            if isUnlocked {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(Typography.caption2())
                    Text(statusLabel)
                        .font(Typography.caption2(weight: .bold, design: .rounded))
                }
                .foregroundStyle(gem.color)
            } else {
                VStack(spacing: 3) {
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.1))
                            Capsule()
                                .fill(gem.color.opacity(0.7))
                                .frame(width: max(3, geo.size.width * CGFloat(progressCurrent) / CGFloat(max(1, progressTotal))))
                        }
                    }
                    .frame(height: 3)

                    Text(gem.unlockDescription)
                        .font(Typography.caption2(design: .rounded))
                        .foregroundStyle(.white.opacity(0.35))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(height: 26)
            }
        }
        .frame(width: 120, height: 148)
        .padding(.vertical, 12)
        .padding(.horizontal, 10)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.55))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 1)
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

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                // Drag handle
                Capsule()
                    .fill(.white.opacity(0.2))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)

                // Gem Hero Visual
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [gem.color.opacity(0.4), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 70
                            )
                        )
                        .frame(width: 140, height: 140)
                        .blur(radius: 12)

                    RoundedPolygon(sides: 6, cornerRadius: 18)
                        .fill(isUnlocked ? gem.color.opacity(0.25) : Color.white.opacity(0.05))
                        .frame(width: 96, height: 96)

                    RoundedPolygon(sides: 6, cornerRadius: 18)
                        .stroke(isUnlocked ? gem.color : .white.opacity(0.2), lineWidth: 2)
                        .frame(width: 96, height: 96)

                    Image(systemName: gem.fallbackSymbol)
                        .font(Typography.hero(size: 40, weight: .bold, relativeTo: .title))
                        .foregroundStyle(isUnlocked ? gem.color : .white.opacity(0.3))
                }
                .padding(.top, 8)

                // Title & Subtitle
                VStack(spacing: 6) {
                    Text(gem.displayName)
                        .font(Typography.title(weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(gem.subtitle)
                        .font(Typography.subheadline(weight: .semibold, design: .rounded))
                        .foregroundStyle(gem.color)
                }

                // Lore Description Card
                VStack(alignment: .leading, spacing: 10) {
                    Text("ARCHIVE CODEX")
                        .font(Typography.caption2(weight: .bold, design: .rounded))
                        .foregroundStyle(gem.color)
                        .kerning(1)

                    Text(gem.loreDescription)
                        .font(Typography.subheadline(design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineSpacing(4)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(0.6))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                        }
                }
                .padding(.horizontal, 24)

                // Status info
                HStack(spacing: 8) {
                    Image(systemName: isUnlocked ? "checkmark.circle.fill" : "lock.fill")
                        .foregroundStyle(isUnlocked ? .green : .white.opacity(0.4))
                    Text(isUnlocked ? "Unlocked & Shining in your Codex" : "\(gem.unlockDescription) (\(progressCurrent)/\(progressTotal))")
                        .font(Typography.footnote(weight: .semibold, design: .rounded))
                        .foregroundStyle(isUnlocked ? .green : .white.opacity(0.6))
                }

                Spacer()

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
                                .glassEffect(.clear, in: .capsule)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Profile View

public struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var supabase = SupabaseService.shared
    @State private var scoreEngine = LucidScoreEngine.shared

    // Navigation & Sheet states
    @State private var showSettings = false
    @State private var selectedGem: GemMilestone? = nil
    
    // Loaded Stats
    @State private var exercisesCompleted: Int = 0
    @State private var dayStreak: Int = 1
    @State private var isLoading: Bool = true
    
    // Animation triggers
    @State private var avatarAppeared = false
    @State private var statsAppeared = false
    @State private var gemsAppeared = false

    private var profileName: String {
        let name = supabase.currentProfile?.name ?? ""
        return name.isEmpty ? "Visionary" : name
    }

    private var screenTimeHours: Double {
        supabase.currentProfile?.estimatedDailyScreenTimeHours ?? 6.5
    }

    private var timeSavedHours: Double {
        let baseline = screenTimeHours
        let saved = Double(exercisesCompleted) * 0.35 + Double(dayStreak) * 0.2
        return max(0.5, min(baseline, saved))
    }

    private var focusHours: Int {
        exercisesCompleted * 2
    }

    public init() {}

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

                // Main Scrollable Content
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
                }
                .scrollIndicators(.hidden)
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
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.9), Color.black.opacity(0.6), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 0) {
            // Wreath + Avatar
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
                if let email = supabase.currentProfile?.email, !email.isEmpty {
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
                    subtitle: "Visual Vitality"
                )

                StatChip(
                    icon: "flame.fill",
                    value: "\(dayStreak)",
                    label: "Day Streak",
                    color: .orange,
                    subtitle: "Active Run"
                )
            }

            HStack(spacing: 10) {
                StatChip(
                    icon: "hourglass",
                    value: "\(focusHours)h",
                    label: "Focus Time",
                    color: .teal,
                    subtitle: "Restored Rest"
                )

                StatChip(
                    icon: "checkmark.circle.fill",
                    value: "\(exercisesCompleted)",
                    label: "Exercises",
                    color: .green,
                    subtitle: "Sessions Done"
                )
            }
        }
        .padding(.horizontal, 18)
        .offset(y: statsAppeared ? 0 : 25)
        .opacity(statsAppeared ? 1 : 0)
        .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.15), value: statsAppeared)
        .padding(.bottom, 28)
    }

    // MARK: - Gemstones Section
    private var gemstonesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.white.opacity(0.85))
                        .font(Typography.headline())
                    Text("Milestone Gemstones")
                        .font(Typography.title3(weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                Spacer()

                Text("\(unlockedCount)/\(gemCatalog.count) Unlocked")
                    .font(Typography.subheadline(weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background {
                        Capsule().fill(.white.opacity(0.08))
                    }
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    Spacer().frame(width: 8)

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
                            .spring(response: 0.55, dampingFraction: 0.8).delay(0.08 * Double(idx)),
                            value: gemsAppeared
                        )
                    }

                    Spacer().frame(width: 8)
                }
            }
        }
        .padding(.bottom, 28)
    }

    // MARK: - Prescription Section
    private var prescriptionSection: some View {
        Group {
            if let profile = supabase.currentProfile {
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
                        Image(systemName: "laptopcomputer")
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

            if let peakTime = supabase.currentProfile?.peakFatigueTime {
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
    private var unlockedCount: Int {
        gemCatalog.filter {
            $0.unlockCondition.isUnlocked(exercises: exercisesCompleted, streak: dayStreak, screenTimeSaved: timeSavedHours)
        }.count
    }

    private func loadStats() {
        exercisesCompleted = UserDefaults.standard.integer(forKey: "lucid_exercises_completed")
        dayStreak = max(1, UserDefaults.standard.integer(forKey: "lucid_day_streak"))
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

#Preview {
    ProfileView()
}
