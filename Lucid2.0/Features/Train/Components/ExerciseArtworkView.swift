//
//  ExerciseArtworkView.swift
//  Lucid2.0
//
//  High-fidelity multi-SF-Symbol dynamic artwork replacement for exercise photos.
//  Features rich glowing auras, multi-symbol interactive compositions,
//  and coordinated animated shade transitions into active exercise sessions.
//

import SwiftUI

public enum ExerciseArtworkStyle {
    /// 160x160 square thumbnail for horizontal carousel cards
    case card
    /// 110x110 left thumbnail with side fade for Recommended exercise card
    case banner
    /// Full width 240pt hero banner for exercise detail sheet
    case hero
    /// Fullscreen animated shade transition
    case fullShade
}

public struct ExerciseArtworkView: View {
    public let exerciseId: String
    public let title: String
    public let style: ExerciseArtworkStyle
    public var isLaunching: Bool = false

    @State private var animPhase: CGFloat = 0
    @State private var isPulsing: Bool = false
    @State private var orbitAngle: Double = 0
    @State private var jumpToggle: Bool = false
    @State private var blinkToggle: Bool = false
    @State private var convergencePhase: CGFloat = 0

    public init(
        exerciseId: String,
        title: String,
        style: ExerciseArtworkStyle = .card,
        isLaunching: Bool = false
    ) {
        self.exerciseId = exerciseId
        self.title = title
        self.style = style
        self.isLaunching = isLaunching
    }

    public init(exercise: ExerciseDefinition, style: ExerciseArtworkStyle = .card, isLaunching: Bool = false) {
        self.init(exerciseId: exercise.id, title: exercise.title, style: style, isLaunching: isLaunching)
    }

    public init(test: TestDefinition, style: ExerciseArtworkStyle = .card, isLaunching: Bool = false) {
        self.init(exerciseId: test.id, title: test.title, style: style, isLaunching: isLaunching)
    }

    // MARK: - Theme Colors

    private var themePrimary: Color {
        switch exerciseId {
        case "smooth_pursuits":
            return Color(red: 0.10, green: 0.85, blue: 0.95) // Electric Cyan
        case "saccadic_jumps":
            return Palette.amber                              // Solar Amber
        case "blink_training":
            return Color(red: 0.22, green: 0.88, blue: 0.82) // Dewdrop Teal
        case "neck_mobility":
            return Color(red: 0.25, green: 0.88, blue: 0.58) // Vibrant Mint
        case "near_far_focus":
            return Color(red: 0.35, green: 0.65, blue: 1.00) // Sapphire Blue
        case "figure_8":
            return Color(red: 0.78, green: 0.45, blue: 1.00) // Radiant Violet
        case "pencil_pushup":
            return Color(red: 1.00, green: 0.60, blue: 0.20) // Bright Gold/Ember
        case "landolt_c":
            return Color(red: 0.30, green: 0.82, blue: 1.00) // Optical Cyan
        case "osdi":
            return Color(red: 0.20, green: 0.85, blue: 0.78) // Tear Hydration
        default:
            return Palette.amber
        }
    }

    private var themeSecondary: Color {
        switch exerciseId {
        case "smooth_pursuits":
            return Color(red: 0.12, green: 0.45, blue: 0.92)
        case "saccadic_jumps":
            return Palette.ember
        case "blink_training":
            return Color(red: 0.08, green: 0.50, blue: 0.85)
        case "neck_mobility":
            return Color(red: 0.08, green: 0.50, blue: 0.40)
        case "near_far_focus":
            return Color(red: 0.65, green: 0.35, blue: 0.95)
        case "figure_8":
            return Color(red: 0.95, green: 0.35, blue: 0.75)
        case "pencil_pushup":
            return Color(red: 0.98, green: 0.32, blue: 0.25)
        case "landolt_c":
            return Color(red: 0.12, green: 0.45, blue: 0.90)
        case "osdi":
            return Palette.amber
        default:
            return Palette.ember
        }
    }

    // MARK: - Body

    public var body: some View {
        ZStack {
            // 1. Deep atmospheric background
            backgroundGradient

            // 2. Multi-tier luminous aura
            ambientGlowField

            // 3. Exercise-specific multi-SF-Symbol composition
            symbolComposition
                .scaleEffect(contentScale)

            // 4. Subtle holographic scanline / shimmer
            shimmerOverlay
        }
        .clipped()
        .onAppear {
            startLoopingAnimations()
        }
    }

    // MARK: - Scale & Sizing

    private var contentScale: CGFloat {
        let launchMultiplier: CGFloat = isLaunching ? 1.15 : 1.0
        switch style {
        case .card:
            return 0.85 * launchMultiplier
        case .banner:
            return 0.78 * launchMultiplier
        case .hero:
            return 1.12 * launchMultiplier
        case .fullShade:
            return 1.40 * launchMultiplier
        }
    }

    // MARK: - Background Layers

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.04, green: 0.06, blue: 0.12),
                Color(red: 0.02, green: 0.03, blue: 0.07)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var ambientGlowField: some View {
        ZStack {
            // Core colored bloom
            RadialGradient(
                colors: [
                    themePrimary.opacity(isLaunching ? 0.45 : (isPulsing ? 0.32 : 0.20)),
                    themeSecondary.opacity(0.12),
                    Color.clear
                ],
                center: .center,
                startRadius: 8,
                endRadius: style == .hero || style == .fullShade ? 180 : 90
            )

            // Dynamic breathing outer ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [themePrimary.opacity(0.35), themeSecondary.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: style == .hero ? 190 : 120, height: style == .hero ? 190 : 120)
                .scaleEffect(isPulsing ? 1.08 : 0.96)
                .opacity(isPulsing ? 0.8 : 0.4)
                .blur(radius: 0.5)
        }
    }

    private var shimmerOverlay: some View {
        LinearGradient(
            colors: [
                Color.white.opacity(0),
                themePrimary.opacity(isLaunching ? 0.15 : 0.05),
                Color.white.opacity(0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .allowsHitTesting(false)
    }

    // MARK: - Exercise Symbol Compositions

    @ViewBuilder
    private var symbolComposition: some View {
        switch exerciseId {
        case "smooth_pursuits":
            smoothPursuitsArtwork
        case "saccadic_jumps":
            saccadicJumpsArtwork
        case "blink_training":
            blinkTrainingArtwork
        case "neck_mobility":
            neckMobilityArtwork
        case "near_far_focus":
            nearFarFocusArtwork
        case "figure_8":
            figure8Artwork
        case "pencil_pushup":
            pencilPushupArtwork
        case "landolt_c":
            landoltCArtwork
        case "osdi":
            osdiArtwork
        default:
            defaultArtwork
        }
    }

    // MARK: 1. Smooth Pursuits: Eye + Orbiting Target + Reticle Scope + Sparkles
    private var smoothPursuitsArtwork: some View {
        ZStack {
            // Rotating outer reticle
            Image(systemName: "scope")
                .font(.system(size: 88, weight: .light))
                .foregroundStyle(themePrimary.opacity(0.3))
                .rotationEffect(.degrees(orbitAngle))

            // Background concentric coordinate rings
            Image(systemName: "circle.circle")
                .font(.system(size: 64, weight: .ultraLight))
                .foregroundStyle(themeSecondary.opacity(0.45))

            // Central radiant eye
            Image(systemName: "eye.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, themePrimary],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: themePrimary.opacity(0.85), radius: isLaunching ? 18 : 10)
                .scaleEffect(isPulsing ? 1.05 : 0.95)

            // Orbiting pursuit target dot tracing a smooth elliptical path
            let radiusX: CGFloat = style == .hero ? 62 : 46
            let radiusY: CGFloat = style == .hero ? 44 : 32
            let rad = orbitAngle * .pi / 180.0
            let posX = cos(rad) * radiusX
            let posY = sin(rad) * radiusY

            ZStack {
                // Outer target glow
                Circle()
                    .fill(themePrimary.opacity(0.4))
                    .frame(width: 22, height: 22)
                    .blur(radius: 4)

                // High-visibility tracking bead
                Circle()
                    .fill(Color.white)
                    .frame(width: 10, height: 10)
                    .shadow(color: themePrimary, radius: 8)

                // Tracking target crosshair
                Image(systemName: "circle.grid.cross")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(themePrimary)
            }
            .offset(x: posX, y: posY)

            // Sparkling guiding stars
            Image(systemName: "sparkles")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(themePrimary.opacity(0.7))
                .offset(x: -radiusX * 0.9, y: -radiusY * 0.8)
                .opacity(isPulsing ? 0.9 : 0.3)
        }
    }

    // MARK: 2. Saccadic Jumps: Bolt Impulse + Alternating Targets + Ping-Pong Reticle
    private var saccadicJumpsArtwork: some View {
        ZStack {
            // Speed impulse lightning in center
            Image(systemName: "bolt.horizontal.fill")
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Palette.amber, Palette.ember],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: Palette.amber.opacity(0.9), radius: isLaunching ? 22 : 12)
                .scaleEffect(jumpToggle ? 1.12 : 0.95)

            // Left target reticle
            HStack(spacing: style == .hero ? 110 : 74) {
                // Left Hop target
                ZStack {
                    Image(systemName: "target")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(jumpToggle ? Palette.amber : Color.white.opacity(0.3))

                    if jumpToggle {
                        Circle()
                            .fill(Palette.amber)
                            .frame(width: 8, height: 8)
                            .shadow(color: Palette.amber, radius: 8)
                    }
                }
                .scaleEffect(jumpToggle ? 1.2 : 0.9)

                // Right Hop target
                ZStack {
                    Image(systemName: "target")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(!jumpToggle ? Palette.amber : Color.white.opacity(0.3))

                    if !jumpToggle {
                        Circle()
                            .fill(Palette.amber)
                            .frame(width: 8, height: 8)
                            .shadow(color: Palette.amber, radius: 8)
                    }
                }
                .scaleEffect(!jumpToggle ? 1.2 : 0.9)
            }

            // Directional indicators
            Image(systemName: "arrow.left.and.right")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Palette.honey.opacity(0.75))
                .offset(y: 38)

            // Burst sparkles
            Image(systemName: "sparkle")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Palette.amber)
                .offset(x: jumpToggle ? -40 : 40, y: -26)
                .opacity(jumpToggle ? 1.0 : 0.3)
        }
    }

    // MARK: 3. Blink Training: Eyelid Flutter + Moisture Droplet + Expanding Hydration Waves
    private var blinkTrainingArtwork: some View {
        ZStack {
            // Expanding moisture ripple waves
            ForEach(0..<3) { i in
                Circle()
                    .stroke(
                        themePrimary.opacity(0.35 - Double(i) * 0.1),
                        lineWidth: 1.2
                    )
                    .frame(
                        width: CGFloat(60 + i * 32) * (isPulsing ? 1.15 : 0.9),
                        height: CGFloat(60 + i * 32) * (isPulsing ? 1.15 : 0.9)
                    )
            }

            // Central Eye that blinks smoothly between open & resting lid
            ZStack {
                // Open Eye
                Image(systemName: "eye.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, themePrimary],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .opacity(blinkToggle ? 0.15 : 1.0)
                    .scaleEffect(blinkToggle ? 0.92 : 1.05)

                // Gentle closed/winking blink lid
                Image(systemName: "eye.slash.fill")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(themePrimary)
                    .opacity(blinkToggle ? 1.0 : 0.0)
                    .scaleEffect(blinkToggle ? 1.05 : 0.85)
            }
            .shadow(color: themePrimary.opacity(0.85), radius: 14)

            // Rejuvenating teardrop floating gently down
            ZStack {
                Image(systemName: "drop.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, themePrimary, themeSecondary],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: themePrimary, radius: 10)
            }
            .offset(x: 28, y: isPulsing ? 24 : 14)

            // Dewdrop sparkles
            HStack(spacing: 48) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.white.opacity(0.8))
                Image(systemName: "sparkle")
                    .font(.system(size: 14))
                    .foregroundStyle(themePrimary)
            }
            .offset(y: -34)
            .opacity(isPulsing ? 0.9 : 0.4)
        }
    }

    // MARK: 4. Neck Mobility: Posture Figure + Dual Rotation Loop + Gyroscope Tilt
    private var neckMobilityArtwork: some View {
        ZStack {
            // Rotating cervical orbit ring
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 80, weight: .ultraLight))
                .foregroundStyle(themePrimary.opacity(0.4))
                .rotationEffect(.degrees(orbitAngle * 0.8))

            // Gyroscope balance reticle
            Image(systemName: "gyroscope")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(themeSecondary.opacity(0.55))
                .rotationEffect(.degrees(isPulsing ? 18 : -18))

            // Central mobility posture figure
            Image(systemName: "figure.walk")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, themePrimary],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: themePrimary.opacity(0.85), radius: 12)
                .rotationEffect(.degrees(isPulsing ? 8 : -8))

            // Dynamic rotation arrows left & right
            HStack(spacing: style == .hero ? 80 : 54) {
                Image(systemName: "arrow.counterclockwise.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(themePrimary.opacity(isPulsing ? 0.9 : 0.4))

                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(themePrimary.opacity(isPulsing ? 0.4 : 0.9))
            }
            .offset(y: 34)

            // Tension relief spark
            Image(systemName: "sparkles")
                .font(.system(size: 15))
                .foregroundStyle(themePrimary)
                .offset(x: -30, y: -32)
                .opacity(isPulsing ? 0.9 : 0.4)
        }
    }

    // MARK: 5. Near Far Focus: Depth Viewfinder + Expanding Focal Bullseye + Depth Arrows
    private var nearFarFocusArtwork: some View {
        ZStack {
            // Outer fixed depth frame
            Image(systemName: "viewfinder")
                .font(.system(size: 86, weight: .ultraLight))
                .foregroundStyle(themeSecondary.opacity(0.5))

            // 4-corner depth adjustment expansion arrows
            Image(systemName: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(themePrimary.opacity(0.45))
                .scaleEffect(isPulsing ? 1.15 : 0.88)

            // Shifting focal plane target: simulates dynamic zoom near/far!
            let depthScale: CGFloat = isPulsing ? 1.25 : 0.65
            let depthBlur: CGFloat = isPulsing ? 0 : 2.5

            ZStack {
                // Focal bullseye
                Image(systemName: "dot.scope")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, themePrimary, themeSecondary],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .blur(radius: depthBlur)

                // Central Eye observer inside the reticle
                Image(systemName: "eye.circle.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.white)
                    .shadow(color: themePrimary, radius: 10)
            }
            .scaleEffect(depthScale)
            .shadow(color: themePrimary.opacity(0.8), radius: isLaunching ? 20 : 12)

            // Laser focus confirmation
            Image(systemName: "rays")
                .font(.system(size: 32, weight: .ultraLight))
                .foregroundStyle(themePrimary.opacity(isPulsing ? 0.8 : 0.15))
                .rotationEffect(.degrees(orbitAngle * 0.5))
        }
    }

    // MARK: 6. Figure 8: Giant Luminous Infinity + Animated Trail Target + Central Eye
    private var figure8Artwork: some View {
        ZStack {
            // Radiant infinity base symbol
            Image(systemName: "infinity")
                .font(.system(size: style == .hero ? 105 : 76, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [themePrimary, themeSecondary, Color(red: 0.95, green: 0.4, blue: 0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: themePrimary.opacity(0.8), radius: 14)
                .scaleEffect(isPulsing ? 1.04 : 0.98)

            // Inner observer eye
            Image(systemName: "eye.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.white)
                .shadow(color: themePrimary, radius: 8)

            // Target bead moving along the Lemniscate of Bernoulli (Figure-8)
            let rad = orbitAngle * .pi / 180.0
            let denom = 1.0 + pow(sin(rad), 2)
            let rawX = cos(rad) / denom
            let rawY = (sin(rad) * cos(rad)) / denom
            let spanX: CGFloat = style == .hero ? 48 : 34
            let spanY: CGFloat = style == .hero ? 28 : 20

            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 10, height: 10)
                    .shadow(color: Palette.amber, radius: 8)

                Circle()
                    .stroke(Palette.amber, lineWidth: 2)
                    .frame(width: 16, height: 16)
            }
            .offset(x: CGFloat(rawX) * spanX, y: CGFloat(rawY) * spanY)

            // Gentle relaxation sparkles
            Image(systemName: "sparkles")
                .font(.system(size: 16))
                .foregroundStyle(themePrimary.opacity(0.85))
                .offset(x: 36, y: -26)
                .opacity(isPulsing ? 0.9 : 0.3)
        }
    }

    // MARK: 7. Pencil Push-up: Convergence Target + Dual Converging Eyes + Depth Ticks
    private var pencilPushupArtwork: some View {
        ZStack {
            // Measurement ticks
            Image(systemName: "lines.measurement.horizontal")
                .font(.system(size: 58, weight: .ultraLight))
                .foregroundStyle(themeSecondary.opacity(0.4))

            // Central convergence target beacon (moving near and far)
            Image(systemName: "arrow.up.and.down.and.sparkles")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Palette.amber, Palette.ember],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Palette.amber.opacity(0.9), radius: isLaunching ? 20 : 12)
                .scaleEffect(isPulsing ? 1.15 : 0.92)

            // Dual converging eyes: animate inward towards center and pull apart!
            let eyeSpread: CGFloat = isPulsing ? 18 : 36

            HStack(spacing: eyeSpread * 2) {
                // Left Eye
                Image(systemName: "eye.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Palette.honey)
                    .shadow(color: Palette.amber, radius: 6)

                // Right Eye
                Image(systemName: "eye.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Palette.honey)
                    .shadow(color: Palette.amber, radius: 6)
            }
            .offset(y: 28)

            // Convergence lock marker
            Image(systemName: "arrow.left.and.right.to.line")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Palette.amber.opacity(0.7))
                .offset(y: -32)
        }
    }

    // MARK: 8. Landolt C Test: Acuity Reticle + Orientation Gap + Sharpness Crosshair
    private var landoltCArtwork: some View {
        ZStack {
            Image(systemName: "viewfinder")
                .font(.system(size: 80, weight: .light))
                .foregroundStyle(themePrimary.opacity(0.35))

            // Dashed acuity ring (representing the Landolt C gap)
            Image(systemName: "circle.dashed")
                .font(.system(size: 52, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, themePrimary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .rotationEffect(.degrees(isPulsing ? 90 : 0))
                .shadow(color: themePrimary, radius: 10)

            // Central eye gauge
            Image(systemName: "eye.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.white)

            Image(systemName: "sparkles")
                .font(.system(size: 16))
                .foregroundStyle(themePrimary)
                .offset(x: 32, y: -26)
        }
    }

    // MARK: 9. OSDI Test: Hydration Tear + Clinical Shield + Comfort Pulse
    private var osdiArtwork: some View {
        ZStack {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(themePrimary.opacity(0.35))

            Image(systemName: "drop.fill")
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, themePrimary, Palette.amber],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: themePrimary.opacity(0.85), radius: 12)
                .scaleEffect(isPulsing ? 1.08 : 0.94)

            Image(systemName: "cross.case.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Palette.amber)
                .offset(x: 24, y: 22)
                .shadow(color: Palette.amber, radius: 6)

            Image(systemName: "sparkles")
                .font(.system(size: 14))
                .foregroundStyle(Color.white)
                .offset(x: -24, y: -22)
        }
    }

    // MARK: 10. Default / Fallback Artwork
    private var defaultArtwork: some View {
        ZStack {
            Image(systemName: "circle.grid.cross")
                .font(.system(size: 68, weight: .light))
                .foregroundStyle(themePrimary.opacity(0.35))
                .rotationEffect(.degrees(orbitAngle * 0.4))

            Image(systemName: "eye.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, themePrimary],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: themePrimary.opacity(0.8), radius: 10)
                .scaleEffect(isPulsing ? 1.06 : 0.96)

            Image(systemName: "sparkles")
                .font(.system(size: 18))
                .foregroundStyle(themeSecondary)
                .offset(x: 28, y: -24)
        }
    }

    // MARK: - Loop Animations

    private func startLoopingAnimations() {
        // Continuous slow orbit / rotation
        withAnimation(.linear(duration: isLaunching ? 2.5 : 8.0).repeatForever(autoreverses: false)) {
            orbitAngle = 360
        }

        // Breathing & glowing pulse
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
            isPulsing = true
        }

        // Discrete saccadic jump snap
        Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { _ in
            withAnimation(.spring(response: 0.22, dampingFraction: 0.6)) {
                jumpToggle.toggle()
            }
        }

        // Discrete blink rhythm
        Timer.scheduledTimer(withTimeInterval: 2.2, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.18)) {
                blinkToggle = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
                withAnimation(.easeInOut(duration: 0.22)) {
                    blinkToggle = false
                }
            }
        }
    }
}
