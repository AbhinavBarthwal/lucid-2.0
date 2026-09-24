//
//  HoldToCommitButton.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import SwiftUI

// MARK: - Particle Definition

private struct SparkParticle: Identifiable {
    let id: Int
    let angle: Double
    let speed: Double
    let distanceOffset: Double
    let size: CGFloat
    let colorType: Int
    let sparkleSpeed: Double
    let verticalRatio: Double
}

public struct HoldToCommitButton: View {
    public var title: String = "Hold to Commit"
    public var holdDuration: Double = 1.0
    public var onCommit: () -> Void

    @State private var isHolding: Bool = false
    @State private var touchLocation: CGPoint = CGPoint(x: 150, y: 28)
    @State private var startHoldDate: Date? = nil
    @State private var releaseDate: Date? = nil
    @State private var progressAtRelease: Double = 0.0
    @State private var commitWorkItem: DispatchWorkItem? = nil
    @State private var hasCompleted: Bool = false

    private let amberColor = Palette.amber
    private let emberColor = Palette.ember
    private let honeyColor = Palette.honey
    private let darkEmber = Color(red: 0.75, green: 0.28, blue: 0.01)

    // Pre-generated 80 deterministic particles for high performance 60/120fps
    private static let particles: [SparkParticle] = (0..<80).map { i in
        let angle = Double.random(in: 0...(2 * .pi))
        let speed = Double.random(in: 0.85...1.35)
        let distanceOffset = Double.random(in: -14...22)
        let size = CGFloat.random(in: 3.0...6.5)
        let colorType = i % 4
        let sparkle = Double.random(in: 8...18)
        let squish = Double.random(in: 0.45...0.72)
        return SparkParticle(
            id: i,
            angle: angle,
            speed: speed,
            distanceOffset: distanceOffset,
            size: size,
            colorType: colorType,
            sparkleSpeed: sparkle,
            verticalRatio: squish
        )
    }

    public init(
        title: String = "Hold to Commit",
        holdDuration: Double = 1.0,
        onCommit: @escaping () -> Void
    ) {
        self.title = title
        self.holdDuration = holdDuration
        self.onCommit = onCommit
    }

    public var body: some View {
        GeometryReader { geometry in
            let buttonSize = geometry.size

            TimelineView(.animation(paused: !isHolding && releaseDate == nil)) { timeline in
                let currentProgress = calculateProgress(at: timeline.date)

                ZStack {
                    // 1. Base Glass Track
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .glassEffect(.clear, in: .capsule)
                        .overlay(
                            Capsule()
                                .stroke(amberColor.opacity(0.35 + currentProgress * 0.45), lineWidth: 1.2)
                        )

                    // 2. High-Performance Particle Canvas
                    Canvas { context, size in
                        drawParticleSimulation(
                            context: context,
                            size: size,
                            progress: currentProgress,
                            currentTime: timeline.date.timeIntervalSinceReferenceDate
                        )
                    }
                    .clipShape(Capsule())
                    .allowsHitTesting(false)

                    // 3. Border Stroke Highlight
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    honeyColor.opacity(0.4 + currentProgress * 0.6),
                                    amberColor.opacity(0.2 + currentProgress * 0.5)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1.5
                        )
                        .allowsHitTesting(false)

                    // 4. Button Title (Switches to high-contrast dark tone when filled with warmth)
                    HStack {
                        Spacer()
                        Text(title)
                            .font(Typography.headline())
                            .foregroundStyle(currentProgress > 0.65 ? Color(red: 0.15, green: 0.07, blue: 0.02) : Color.white)
                            .animation(.easeInOut(duration: 0.18), value: currentProgress > 0.65)
                        Spacer()
                    }
                    .allowsHitTesting(false)
                }
                .clipShape(Capsule())
                .background(
                    // Dynamic ambient glow behind the button
                    Capsule()
                        .fill(emberColor.opacity(0.22 + currentProgress * 0.50))
                        .blur(radius: 16 + CGFloat(currentProgress * 16))
                        .offset(y: 8)
                )
            }
            .contentShape(Capsule())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isHolding && !hasCompleted {
                            let clampedX = max(16, min(value.location.x, buttonSize.width - 16))
                            let clampedY = max(10, min(value.location.y, buttonSize.height - 10))
                            touchLocation = CGPoint(x: clampedX, y: clampedY)
                            startHolding()
                        }
                    }
                    .onEnded { _ in
                        if !hasCompleted {
                            cancelHolding()
                        }
                    }
            )
        }
        .frame(height: 56)
    }

    // MARK: - Progress & Easing Calculation

    private func easeInOutCubic(_ t: Double) -> Double {
        if t <= 0 { return 0 }
        if t >= 1 { return 1 }
        return t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2
    }

    private func calculateProgress(at now: Date) -> Double {
        if isHolding, let start = startHoldDate {
            let elapsed = now.timeIntervalSince(start)
            let rawNormalized = min(1.0, max(0.0, elapsed / holdDuration))
            return easeInOutCubic(rawNormalized)
        } else if let release = releaseDate {
            let elapsedSinceRelease = now.timeIntervalSince(release)
            let decayDuration = 0.24
            if elapsedSinceRelease >= decayDuration {
                DispatchQueue.main.async {
                    self.releaseDate = nil
                    self.progressAtRelease = 0.0
                }
                return 0.0
            }
            let decayFraction = elapsedSinceRelease / decayDuration
            let remaining = progressAtRelease * (1.0 - decayFraction)
            return max(0.0, remaining)
        }
        return 0.0
    }

    // MARK: - Hold Actions

    private func startHolding() {
        isHolding = true
        hasCompleted = false
        releaseDate = nil
        startHoldDate = Date()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        // Schedule completion exactly after holdDuration
        commitWorkItem?.cancel()
        let work = DispatchWorkItem { [self] in
            guard isHolding else { return }
            completeHolding()
        }
        commitWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + holdDuration, execute: work)
    }

    private func cancelHolding() {
        commitWorkItem?.cancel()
        commitWorkItem = nil

        if let start = startHoldDate {
            let elapsed = Date().timeIntervalSince(start)
            let rawNormalized = min(1.0, max(0.0, elapsed / holdDuration))
            progressAtRelease = easeInOutCubic(rawNormalized)
        } else {
            progressAtRelease = 0.0
        }

        isHolding = false
        startHoldDate = nil
        releaseDate = Date()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func completeHolding() {
        hasCompleted = true
        isHolding = false
        commitWorkItem = nil

        UINotificationFeedbackGenerator().notificationOccurred(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            onCommit()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                hasCompleted = false
                startHoldDate = nil
                releaseDate = nil
                progressAtRelease = 0.0
            }
        }
    }

    // MARK: - Canvas Particle Rendering

    private func drawParticleSimulation(context: GraphicsContext, size: CGSize, progress: Double, currentTime: TimeInterval) {
        guard progress > 0.005 else { return }

        let dx = max(touchLocation.x, size.width - touchLocation.x)
        let dy = max(touchLocation.y, size.height - touchLocation.y)
        let maxReach = max(60, hypot(dx, dy) * 1.15)
        let currentRadius = maxReach * progress

        // 1. Fluid Luminous Base Fill radiating from the touch location
        let waveRect = CGRect(
            x: touchLocation.x - currentRadius,
            y: touchLocation.y - currentRadius,
            width: currentRadius * 2,
            height: currentRadius * 2
        )

        let radialGradient = Gradient(colors: [
            honeyColor.opacity(min(1.0, 0.90 + progress * 0.10)),
            amberColor.opacity(min(1.0, 0.85 + progress * 0.15)),
            emberColor.opacity(min(1.0, 0.75 + progress * 0.25)),
            darkEmber.opacity(0.0)
        ])

        context.fill(
            Path(ellipseIn: waveRect),
            with: .radialGradient(
                radialGradient,
                center: touchLocation,
                startRadius: 0,
                endRadius: max(1, currentRadius)
            )
        )

        // 2. Shockwave / Leading Wave Edge Ring
        if currentRadius > 6 {
            let ringRect = waveRect.insetBy(dx: 2, dy: 2)
            let ringAlpha = max(0.2, (1.0 - progress * 0.6))
            context.stroke(
                Path(ellipseIn: ringRect),
                with: .color(Color.white.opacity(ringAlpha)),
                lineWidth: 2.5
            )
        }

        // 3. Solid Blend when approaching 100% full
        if progress > 0.84 {
            let fullCapsule = Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: size.height / 2)
            context.fill(
                fullCapsule,
                with: .linearGradient(
                    Gradient(colors: [honeyColor, amberColor, emberColor]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: size.width, y: size.height)
                )
            )
        }

        // 4. Dynamic Flying Particles
        for p in Self.particles {
            let pDistance = currentRadius * p.speed + p.distanceOffset * progress
            guard pDistance > 0 else { continue }

            let turbulentAngle = p.angle + sin(currentTime * p.sparkleSpeed + Double(p.id)) * 0.18
            let px = touchLocation.x + cos(turbulentAngle) * pDistance
            let py = touchLocation.y + sin(turbulentAngle) * pDistance * p.verticalRatio

            let sparklePulse = 0.8 + 0.2 * sin(currentTime * p.sparkleSpeed)
            let distFromWavefront = abs(pDistance - currentRadius)
            let proximityAlpha = max(0.25, 1.0 - min(1.0, distFromWavefront / 38.0))
            let finalAlpha = proximityAlpha * sparklePulse * (1.0 - max(0, progress - 0.94) / 0.06)

            let pSize = p.size * CGFloat(sparklePulse)

            let pColor: Color
            switch p.colorType {
            case 0: pColor = honeyColor
            case 1: pColor = amberColor
            case 2: pColor = Color.white
            default: pColor = emberColor
            }

            let particleRect = CGRect(
                x: px - pSize / 2,
                y: py - pSize / 2,
                width: pSize,
                height: pSize
            )

            // Core particle
            context.fill(Path(ellipseIn: particleRect), with: .color(pColor.opacity(finalAlpha)))

            // Radiant Halo
            let haloRect = particleRect.insetBy(dx: -2.5, dy: -2.5)
            context.fill(Path(ellipseIn: haloRect), with: .color(pColor.opacity(finalAlpha * 0.45)))
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        HoldToCommitButton {
            print("Committed with warm glowing particles!")
        }
        .padding(24)
    }
}
