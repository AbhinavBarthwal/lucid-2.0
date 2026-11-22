//
//  TwentyTwentyLotusView.swift
//  20-20-20 Eye Rest: ARKit gaze + Core Haptics + 20-petal lotus + Liquid Glass
//
//  Requirements
//  • Xcode 26 / iOS 26+ (Liquid Glass, glassEffect, SF Symbols 7 drawOn, FoundationModels)
//  • Physical device with a TrueDepth front camera (ARFaceTrackingConfiguration)
//  • Info.plist → NSCameraUsageDescription:
//    "Used to verify you are looking away from the screen during your eye rest."
//
//  What's inside
//  1. MotivationService   – on-device FoundationModels (LanguageModelSession) with a no-repeat local fallback
//  2. HapticEngineManager – real Core Haptics: rising-sharpness tick, double-thud, 1.4 s crescendo
//  3. ChimePlayer         – synthesized singing-bowl notes on a pentatonic scale, pitch rises petal 1 → 20, panned by petal angle
//  4. EyeRestGazeTracker  – ARKit gaze ray → screen hit test, debounced, plus a blink / eyes-shut check
//  5. LotusPetalShape / LotusPetalView / CoreOrb – the lotus
//  6. TwentyTwentyLotusView – Liquid Glass UI, morphing glass controls, symbol effects
//

import SwiftUI
import ARKit
import CoreHaptics
import AVFoundation
import UIKit
import Combine
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - 1. Motivational Text (FoundationModels → local fallback)

@MainActor
final class MotivationService: ObservableObject {
    private let fallbackPrompts: [String] = [
        "You've hit your screen time milestone. Let's give your eyes a breather with the 20-20-20 reset.",
        "Your focus has been intense! Step back from the pixels and relax your ciliary muscles for 20 seconds.",
        "Screen time limit reached. Trade the blue light for a distant horizon—your eyes will thank you.",
        "Time to unfocus. Let's melt away the digital eye strain with a 20-second gaze into the distance.",
        "Digital pause initiated. Rest your eyes on something 20 feet away and feel the tension fade.",
        "Twenty minutes of glow, twenty seconds of sky. Let your eyes drift to the horizon.",
        "Soft focus, far away. Your eyes have earned a little distance."
    ]

    private let tones = [
        "calm and poetic", "playful and warm", "a gentle coach",
        "zen and minimal", "curious, like a nature lover", "quietly encouraging"
    ]

    private var lastPrompt: String?

    func generateMotivation() async -> String {
        #if canImport(FoundationModels)
        if let aiText = await generateWithFoundationModels() {
            lastPrompt = aiText
            return aiText
        }
        #endif
        try? await Task.sleep(for: .milliseconds(350))
        let text = nextFallback()
        lastPrompt = text
        return text
    }

    private func nextFallback() -> String {
        let pool = fallbackPrompts.filter { $0 != lastPrompt }
        return pool.randomElement() ?? fallbackPrompts[0]
    }

    #if canImport(FoundationModels)
    private func generateWithFoundationModels() async -> String? {
        guard case .available = SystemLanguageModel.default.availability else { return nil }
        let tone = tones.randomElement() ?? "calm"
        do {
            let session = LanguageModelSession(
                instructions: """
                You are a calm wellness guide inside an eye-rest app. Write 1-2 short sentences \
                telling the user they reached their screen time limit and inviting them to do the \
                20-20-20 eye rest (look 20 feet away for 20 seconds). No emojis, no hashtags, no quotes.
                """
            )
            var prompt = "Write a fresh prompt. Tone: \(tone)."
            if let last = lastPrompt {
                prompt += " It must be clearly different from this previous one: \"\(last)\""
            }
            let response = try await session.respond(
                to: prompt,
                options: GenerationOptions(temperature: 1.0)
            )
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? nil : text
        } catch {
            return nil
        }
    }
    #endif
}

// MARK: - 2. Core Haptics

@MainActor
final class HapticEngineManager: ObservableObject {
    private var engine: CHHapticEngine?
    private let supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    init() { prepare() }

    func prepare() {
        guard supportsHaptics else { return }
        if let engine {
            try? engine.start()
            return
        }
        do {
            let e = try CHHapticEngine()
            e.isAutoShutdownEnabled = true
            e.resetHandler = { [weak self] in
                Task { @MainActor in try? self?.engine?.start() }
            }
            try e.start()
            engine = e
        } catch {
            print("Haptic Engine Error: \(error.localizedDescription)")
        }
    }

    private func play(
        events: [CHHapticEvent],
        curves: [CHHapticParameterCurve] = [],
        fallback: () -> Void
    ) {
        guard supportsHaptics, let engine else { fallback(); return }
        do {
            try engine.start()
            let pattern = try CHHapticPattern(events: events, parameterCurves: curves)
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            fallback()
        }
    }

    /// Sharp tap per petal. Gets slightly crisper and stronger as the countdown progresses (0...1).
    func playPetalDropTick(progress: Double) {
        let tap = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(0.6 + 0.3 * progress)),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(0.45 + 0.5 * progress))
            ],
            relativeTime: 0
        )
        play(events: [tap]) {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.65)
        }
    }

    /// Double-thud when the user "cheats" and looks back at the screen.
    func playLookBackWarning() {
        func thud(_ t: TimeInterval, _ i: Float) -> CHHapticEvent {
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: i),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                ],
                relativeTime: t
            )
        }
        let rumble = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.35),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
            ],
            relativeTime: 0,
            duration: 0.2
        )
        play(events: [thud(0, 1.0), thud(0.13, 0.8), rumble]) {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
    }

    /// 1.4 s continuous crescendo + final pop as the golden glow floods the screen.
    func playCompletionSwell() {
        let swell = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
            ],
            relativeTime: 0,
            duration: 1.4
        )
        let pop = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
            ],
            relativeTime: 1.42
        )
        let intensityCurve = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                .init(relativeTime: 0.0, value: 0.15),
                .init(relativeTime: 0.7, value: 0.6),
                .init(relativeTime: 1.4, value: 1.0)
            ],
            relativeTime: 0
        )
        let sharpnessCurve = CHHapticParameterCurve(
            parameterID: .hapticSharpnessControl,
            controlPoints: [
                .init(relativeTime: 0.0, value: 0.1),
                .init(relativeTime: 1.4, value: 0.85)
            ],
            relativeTime: 0
        )
        play(events: [swell, pop], curves: [intensityCurve, sharpnessCurve]) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

// MARK: - 3. Singing-bowl chimes (pentatonic, rising pitch, panned by petal angle)

@MainActor
final class ChimePlayer: ObservableObject {
    private let engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private var buffers: [AVAudioPCMBuffer] = []
    private var nextPlayer = 0
    private var isReady = false

    private let sampleRate: Double = 44_100
    private let pentatonic = [0, 2, 4, 7, 9]          // major pentatonic
    private let baseFrequency = 130.81                // C3 → petal 20 lands near A6

    func prepare() {
        if isReady {
            if !engine.isRunning { try? engine.start() }
            return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Audio session error: \(error.localizedDescription)")
        }

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        buffers = (0..<20).compactMap { makeBowlBuffer(noteIndex: $0, format: format) }

        for _ in 0..<4 {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            players.append(node)
        }

        do {
            try engine.start()
            isReady = true
        } catch {
            print("Audio engine error: \(error.localizedDescription)")
        }
    }

    /// Petal index 0...19: pitch rises, stereo position follows the petal's angle around the lotus.
    func playPetal(index: Int) {
        let pan = Float(sin(Double(index) * 18.0 * .pi / 180.0))
        play(noteIndex: index, pan: pan, volume: 0.7)
    }

    func playFinale() {
        for note in [12, 16, 19] { play(noteIndex: note, pan: 0, volume: 0.6) }
    }

    private func play(noteIndex: Int, pan: Float, volume: Float) {
        guard isReady, buffers.indices.contains(noteIndex) else { return }
        // Respect the "Sound Effects & Audio Cues" setting (Settings > Preferences).
        let soundEnabled = UserDefaults.standard.object(forKey: "lucid_setting_sound") as? Bool ?? true
        guard soundEnabled else { return }
        if !engine.isRunning { try? engine.start() }
        let node = players[nextPlayer]
        nextPlayer = (nextPlayer + 1) % players.count
        node.pan = pan
        node.volume = volume
        node.scheduleBuffer(buffers[noteIndex], at: nil, options: .interrupts)
        if !node.isPlaying { node.play() }
    }

    private func makeBowlBuffer(noteIndex: Int, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let octave = noteIndex / pentatonic.count
        let semitones = Double(octave * 12 + pentatonic[noteIndex % pentatonic.count])
        let f0 = baseFrequency * pow(2.0, semitones / 12.0)

        let duration = 2.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channel = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = frameCount

        // (frequency ratio, amplitude, decay rate)
        let partials: [(Double, Double, Double)] = [
            (1.000, 1.00, 2.2),
            (1.004, 0.50, 2.4),   // slight detune → bowl shimmer
            (2.760, 0.40, 3.4),
            (5.400, 0.18, 5.5)
        ]
        let norm = 0.32 / partials.reduce(0.0) { $0 + $1.1 }

        for n in 0..<Int(frameCount) {
            let t = Double(n) / sampleRate
            let attack = min(t / 0.004, 1.0)
            var sample = 0.0
            for (ratio, amp, decay) in partials {
                sample += amp * sin(2.0 * .pi * f0 * ratio * t) * exp(-decay * t)
            }
            channel[n] = Float(sample * attack * norm * 3.0)
        }
        return buffer
    }
}

// MARK: - 4. ARKit gaze + blink tracker

final class EyeRestGazeTracker: NSObject, ObservableObject, ARSessionDelegate {
    private let session = ARSession()

    /// True when the user is looking away from the screen (or the face is out of frame / turned away).
    @Published private(set) var isLookingAway: Bool = true
    /// True when both eyes have been shut > 2 s (we want them open and soft-focused on the distance).
    @Published private(set) var eyesClosedTooLong: Bool = false
    let isSupported: Bool = ARFaceTrackingConfiguration.isSupported

    // Tunables
    private let screenGazeRadius: Float = 0.14     // metres around the lens that count as "the screen"
    private let resumeDelay: TimeInterval = 0.4    // gaze must stay off-screen this long before we resume
    private let blinkThreshold: Float = 0.85
    private let closedLimit: TimeInterval = 2.0

    private var awaySince: Date?
    private var closedSince: Date?

    func startTracking() {
        awaySince = nil
        closedSince = nil
        isLookingAway = true
        eyesClosedTooLong = false

        guard isSupported else { return } // no TrueDepth → behaves as a plain 20 s timer
        let config = ARFaceTrackingConfiguration()
        config.isLightEstimationEnabled = false
        session.delegate = self
        session.delegateQueue = .main
        session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }

    func stopTracking() {
        session.pause()
    }

    // MARK: ARSessionDelegate (delivered on the main queue)

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard
            let face = anchors.compactMap({ $0 as? ARFaceAnchor }).first,
            face.isTracked,
            let frame = session.currentFrame
        else {
            markAway()
            resetBlink()
            return
        }
        update(gazeAtScreen: isGazeOnScreen(face: face, frame: frame))
        updateBlink(face: face)
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        if anchors.contains(where: { $0 is ARFaceAnchor }) {
            markAway()
            resetBlink()
        }
    }

    // MARK: Gaze math

    /// Casts the eyes' gaze ray (eye midpoint → lookAtPoint) in camera space and checks where it
    /// pierces the plane of the phone. Orientation-agnostic: we only use the distance from the lens.
    private func isGazeOnScreen(face: ARFaceAnchor, frame: ARFrame) -> Bool {
        let toCamera = simd_inverse(frame.camera.transform) * face.transform

        func point(_ m: simd_float4x4, _ p: SIMD4<Float>) -> SIMD3<Float> {
            let r = m * p
            return SIMD3(r.x, r.y, r.z)
        }

        let left = point(toCamera, face.leftEyeTransform.columns.3)
        let right = point(toCamera, face.rightEyeTransform.columns.3)
        let origin = (left + right) / 2
        let target = point(toCamera, SIMD4(face.lookAtPoint, 1))
        let direction = target - origin

        // Camera looks down -Z; the face sits at negative Z. Gaze heading toward the lens has +Z.
        guard direction.z > 0.001 else { return false }

        let t = -origin.z / direction.z
        let hit = origin + direction * t
        return hypot(hit.x, hit.y) < screenGazeRadius
    }

    private func update(gazeAtScreen: Bool) {
        if gazeAtScreen {
            awaySince = nil
            setAway(false)
        } else {
            let since = awaySince ?? Date()
            awaySince = since
            if Date().timeIntervalSince(since) >= resumeDelay { setAway(true) }
        }
    }

    private func markAway() {
        awaySince = nil
        setAway(true)
    }

    private func setAway(_ value: Bool) {
        if isLookingAway != value { isLookingAway = value }
    }

    // MARK: Blink check (ciliary muscles relax best with eyes open, focused far away)

    private func updateBlink(face: ARFaceAnchor) {
        let l = face.blendShapes[.eyeBlinkLeft]?.floatValue ?? 0
        let r = face.blendShapes[.eyeBlinkRight]?.floatValue ?? 0
        if l > blinkThreshold && r > blinkThreshold {
            let since = closedSince ?? Date()
            closedSince = since
            if Date().timeIntervalSince(since) >= closedLimit, !eyesClosedTooLong {
                eyesClosedTooLong = true
            }
        } else {
            resetBlink()
        }
    }

    private func resetBlink() {
        closedSince = nil
        if eyesClosedTooLong { eyesClosedTooLong = false }
    }
}

// MARK: - 5. Lotus pieces

enum ExercisePhase {
    case intro, activeTimer, completed
}

enum LotusPetalState {
    case bud, open, fallen
}

struct LotusPetalShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midX = rect.midX

        // Starts at the bottom tip (attached to the core) and blooms outward
        path.move(to: CGPoint(x: midX, y: height))
        path.addCurve(
            to: CGPoint(x: midX, y: 0),
            control1: CGPoint(x: midX - width * 0.65, y: height * 0.65),
            control2: CGPoint(x: midX - width * 0.35, y: height * 0.2)
        )
        path.addCurve(
            to: CGPoint(x: midX, y: height),
            control1: CGPoint(x: midX + width * 0.35, y: height * 0.2),
            control2: CGPoint(x: midX + width * 0.65, y: height * 0.65)
        )
        path.closeSubpath()
        return path
    }
}

/// One petal. A single `state` drives every transform, so bloom and fall never fight over animations.
struct LotusPetalView: View {
    let index: Int
    let total: Int
    let state: LotusPetalState

    var body: some View {
        let angle = Double(index) * (360.0 / Double(total))
        let side: CGFloat = index.isMultiple(of: 2) ? 1 : -1
        let petalHeight: CGFloat = index.isMultiple(of: 2) ? 88 : 78      // alternating lengths = depth
        let fallen = state == .fallen
        let bud = state == .bud

        LotusPetalShape()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.45, blue: 0.75),
                        Color(red: 0.65, green: 0.25, blue: 0.95),
                        Color.yellow.opacity(0.9)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 28, height: petalHeight)
            .shadow(color: .cyan.opacity(0.7), radius: 10)      // peripheral-vision glow
            .offset(y: -(20 + petalHeight / 2))                  // tip sits at the core
            .rotationEffect(.degrees(angle + (bud ? -60 : 0)))   // fans open while blooming
            .offset(x: fallen ? side * 35 : 0, y: fallen ? 320 : 0)
            .rotationEffect(.degrees(fallen ? Double(side) * 40 : 0))
            .scaleEffect(bud ? 0.08 : (fallen ? 0.4 : 1.0))
            .opacity(bud ? 0 : (fallen ? 0 : 0.92))
            .animation(
                fallen
                    ? .easeIn(duration: 1.8)
                    : .spring(duration: 1.1, bounce: 0.35).delay(Double(index) * 0.04),
                value: state
            )
    }
}

struct CoreOrb: View {
    let isCompleted: Bool
    let isLookingAway: Bool

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [.white, .yellow, Color.orange.opacity(0.85)],
                    center: .center,
                    startRadius: 2,
                    endRadius: 36
                )
            )
            .frame(width: 64, height: 64)
            .shadow(color: .yellow, radius: 24)
            .shadow(color: .orange.opacity(0.8), radius: 40)
            .phaseAnimator([0.9, 1.1]) { content, scale in
                content.scaleEffect(isCompleted ? 1.3 : scale)
            } animation: { _ in
                .easeInOut(duration: 1.6)
            }
            .opacity(isLookingAway ? 1 : 0.55)
            .animation(.smooth(duration: 0.4), value: isLookingAway)
    }
}

private struct IntroAurora: View {
    var body: some View {
        ZStack {
            Circle().fill(Color.purple.opacity(0.55)).frame(width: 280).offset(x: -110, y: -260)
            Circle().fill(Color.cyan.opacity(0.45)).frame(width: 320).offset(x: 130, y: 20)
            Circle().fill(Color.pink.opacity(0.40)).frame(width: 260).offset(x: -90, y: 300)
            Circle().fill(Color.yellow.opacity(0.28)).frame(width: 200).offset(x: 120, y: -120)
        }
        .blur(radius: 70)
        .phaseAnimator([false, true]) { view, drift in
            view
                .offset(x: drift ? 24 : -24, y: drift ? -18 : 18)
                .scaleEffect(drift ? 1.08 : 0.95)
        } animation: { _ in
            .easeInOut(duration: 5)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

private extension View {
    /// Springy blur-in entrance, staggered by index.
    func stagger(_ appeared: Bool, _ index: Int) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 26)
            .blur(radius: appeared ? 0 : 10)
            .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.1 * Double(index)), value: appeared)
    }
}

// MARK: - 6. Main view

@available(iOS 26.0, *)
struct TwentyTwentyLotusView: View {
    @StateObject private var gaze = EyeRestGazeTracker()
    @StateObject private var haptics = HapticEngineManager()
    @StateObject private var chimes = ChimePlayer()
    @StateObject private var motivation = MotivationService()

    @State private var phase: ExercisePhase
    @State private var motivationalText = "Composing your eye rest prompt…"
    @State private var elapsedSeconds = 0
    @State private var bloomed: Bool
    @State private var flood = false
    @State private var showWellDone = false
    @State private var introAppeared = false
    @State private var peekCount = 0
    @State private var headerTaps = 0
    @State private var sparkleDrawn = false

    /// Called once the "Well Done" card is dismissed, so hosts (e.g. the Protect tab)
    /// can dismiss this fullScreenCover and record the completion.
    public var onCompleted: (() -> Void)?

    @Namespace private var glassNS

    private let totalPetals = 20

    init(initialPhase: ExercisePhase = .intro, onCompleted: (() -> Void)? = nil) {
        _phase = State(initialValue: initialPhase)
        _bloomed = State(initialValue: initialPhase != .intro)
        self.onCompleted = onCompleted
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if phase == .intro {
                IntroAurora().transition(.opacity)
                introContent
                    .transition(
                        .asymmetric(
                            insertion: .opacity,
                            removal: .scale(scale: 1.12).combined(with: .opacity)
                        )
                    )
            }

            if phase != .intro {
                lotusStage.transition(.opacity)
            }

            glassDock

            if showWellDone {
                wellDoneCard
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .preferredColorScheme(.dark)
        .task {
            if phase == .intro { playIntroEntrance() }
            motivationalText = await motivation.generateMotivation()
        }
        .task(id: phase) {
            guard phase == .activeTimer else { return }
            while !Task.isCancelled && phase == .activeTimer {
                try? await Task.sleep(for: .seconds(1))
                handleTick()
            }
        }
        .onChange(of: gaze.isLookingAway) { _, away in
            guard phase == .activeTimer, !away else { return }
            peekCount += 1
            haptics.playLookBackWarning()
        }
        .onDisappear { gaze.stopTracking() }
    }

    // MARK: Intro

    private var introContent: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 20)

            Image(systemName: "eye.circle.fill")
                .font(.system(size: 58))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .yellow)
                .symbolEffect(.breathe, options: .repeating)
                .symbolEffect(.bounce, value: headerTaps)
                .frame(width: 120, height: 120)
                .glassEffect(.regular.tint(.yellow.opacity(0.25)).interactive(), in: Circle())
                .onTapGesture { headerTaps += 1 }
                .stagger(introAppeared, 0)

            Text("20 • 20 • 20 Reset")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .stagger(introAppeared, 1)

            Text(motivationalText)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.78))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)
                .stagger(introAppeared, 2)

            Spacer()
        }
        .padding(.bottom, 130)
    }

    private func tipRow(_ index: Int, symbol: String, text: String, variable: Bool = false) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.yellow)
                .frame(width: 30)
                .symbolEffect(.variableColor.iterative.reversing, options: .repeating, isActive: variable)
                .symbolEffect(.pulse, options: .repeating, isActive: !variable)
            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.88))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
        .stagger(introAppeared, index)
    }

    // MARK: Lotus stage

    private var lotusStage: some View {
        ZStack {
            // Peripheral haze
            RadialGradient(
                colors: [.cyan.opacity(0.22), .clear],
                center: .center,
                startRadius: 10,
                endRadius: 260
            )
            .frame(width: 520, height: 520)
            .blur(radius: 30)
            .opacity(bloomed ? (gaze.isLookingAway ? 1 : 0.4) : 0)
            .animation(.easeOut(duration: 1.0), value: bloomed)
            .animation(.smooth, value: gaze.isLookingAway)

            ForEach(0..<totalPetals, id: \.self) { index in
                LotusPetalView(index: index, total: totalPetals, state: petalState(for: index))
            }

            CoreOrb(isCompleted: phase == .completed, isLookingAway: gaze.isLookingAway)
                .scaleEffect(bloomed ? 1 : 0.2)
                .animation(.spring(duration: 0.9, bounce: 0.4), value: bloomed)

            // Golden flood on completion
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, .yellow, .orange],
                        center: .center,
                        startRadius: 0,
                        endRadius: 32
                    )
                )
                .frame(width: 64, height: 64)
                .scaleEffect(flood ? 30 : 0.001)
                .opacity(flood ? 1 : 0)
                .allowsHitTesting(false)
        }
    }

    private func petalState(for index: Int) -> LotusPetalState {
        guard bloomed else { return .bud }
        return index < elapsedSeconds ? .fallen : .open
    }

    // MARK: Liquid Glass dock (morphs between intro / active states)

    private var glassDock: some View {
        VStack {
            Spacer()
            GlassEffectContainer(spacing: 24) {
                VStack(spacing: 14) {
                    if phase == .intro {
                        startButton
                    }
                    if phase == .activeTimer {
                        if gaze.eyesClosedTooLong { eyesClosedPill }
                        if !gaze.isLookingAway { warningPill }
                        statusPill
                    }
                }
            }
            .padding(.bottom, 36)
            .animation(.bouncy(duration: 0.55), value: gaze.isLookingAway)
            .animation(.bouncy(duration: 0.55), value: gaze.eyesClosedTooLong)
        }
    }

    private var startButton: some View {
        PulsingActionButton(title: "Begin Exercise", systemImage: "leaf.fill", action: startExercise)
            .glassEffectID("action", in: glassNS)
            .padding(.horizontal, 36)
            .stagger(introAppeared, 6)
    }

    private var statusPill: some View {
        Label("\(totalPetals - elapsedSeconds)s left — keep looking away", systemImage: "checkmark.circle.fill")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .glassEffect(
                .regular.tint((gaze.isLookingAway ? Color.cyan : Color.orange).opacity(0.28)),
                in: Capsule()
            )
            .glassEffectID("action", in: glassNS)
    }

    private var warningPill: some View {
        Label("Looking at the screen. Look 20 ft away.", systemImage: "exclamationmark.triangle.fill")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .symbolEffect(.pulse, options: .repeating)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .glassEffect(.regular.tint(.orange.opacity(0.55)), in: Capsule())
            .glassEffectID("warn", in: glassNS)
            .glassEffectTransition(.materialize)
    }

    private var eyesClosedPill: some View {
        Label("Keep your eyes open, soft focus far away", systemImage: "eye.fill")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .symbolEffect(.variableColor.iterative, options: .repeating)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .glassEffect(.regular.tint(.purple.opacity(0.5)), in: Capsule())
            .glassEffectID("eyes", in: glassNS)
            .glassEffectTransition(.materialize)
    }

    // MARK: Finale card

    private var wellDoneCard: some View {
        GlassEffectContainer(spacing: 20) {
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 54, weight: .bold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.black.opacity(0.88))
                    .symbolEffect(.drawOn, isActive: !sparkleDrawn)
                    .symbolEffect(.bounce.up.byLayer, value: sparkleDrawn)

                Text("Well Done")
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .foregroundStyle(.black)

                Text("Your eyes are refreshed and ready.")
                    .font(.headline)
                    .foregroundStyle(.black.opacity(0.75))

                Button(action: resetExercise) {
                    Label("Done", systemImage: "checkmark")
                        .font(.headline)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)
                .tint(.black)
                .padding(.top, 10)
            }
            .padding(.vertical, 36)
            .padding(.horizontal, 36)
            .glassEffect(.regular.tint(.white.opacity(0.3)), in: .rect(cornerRadius: 44))
        }
        .padding(.horizontal, 28)
    }

    // MARK: Lifecycle

    private func playIntroEntrance() {
        introAppeared = false
        Task {
            try? await Task.sleep(for: .milliseconds(80))
            introAppeared = true
        }
    }

    private func startExercise() {
        haptics.prepare()
        chimes.prepare()

        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) {
            elapsedSeconds = 0
            flood = false
            showWellDone = false
            sparkleDrawn = false
            bloomed = false
        }

        gaze.startTracking()
        haptics.playPetalDropTick(progress: 0)

        withAnimation(.smooth(duration: 0.7)) { phase = .activeTimer }

        Task {
            try? await Task.sleep(for: .milliseconds(250))
            bloomed = true
        }
    }

    private func handleTick() {
        guard phase == .activeTimer, elapsedSeconds < totalPetals else { return }

        if gaze.isLookingAway {
            withAnimation(.smooth) { elapsedSeconds += 1 }
            haptics.playPetalDropTick(progress: Double(elapsedSeconds) / Double(totalPetals))
            chimes.playPetal(index: elapsedSeconds - 1)
            if elapsedSeconds == totalPetals { triggerCompletionFinale() }
        } else {
            // Peeking: hold the countdown and nudge them
            haptics.playLookBackWarning()
        }
    }

    private func triggerCompletionFinale() {
        gaze.stopTracking()
        Task {
            // Let the 20th petal start its fall before the core detonates with light
            try? await Task.sleep(for: .milliseconds(450))
            withAnimation(.smooth(duration: 0.5)) { phase = .completed }
            haptics.playCompletionSwell()
            chimes.playFinale()

            withAnimation(.easeIn(duration: 1.3)) { flood = true }

            try? await Task.sleep(for: .milliseconds(1100))
            withAnimation(.spring(duration: 0.6, bounce: 0.3)) { showWellDone = true }

            try? await Task.sleep(for: .milliseconds(250))
            sparkleDrawn = true
        }
    }

    private func resetExercise() {
        guard let onCompleted else {
            replayFromIntro()
            return
        }
        withAnimation(.smooth(duration: 0.5)) {
            showWellDone = false
            flood = false
        }
        Task {
            try? await Task.sleep(for: .milliseconds(450))
            onCompleted()
        }
    }

    private func replayFromIntro() {
        withAnimation(.smooth(duration: 0.5)) {
            showWellDone = false
            flood = false
        }
        Task {
            try? await Task.sleep(for: .milliseconds(450))

            var t = Transaction()
            t.disablesAnimations = true
            withTransaction(t) {
                elapsedSeconds = 0
                bloomed = false
                sparkleDrawn = false
                introAppeared = false
            }

            withAnimation(.smooth(duration: 0.7)) { phase = .intro }
            playIntroEntrance()

            let next = await motivation.generateMotivation()
            motivationalText = next
        }
    }
}

// MARK: - Preview

@available(iOS 26.0, *)
#Preview("Intro") {
    TwentyTwentyLotusView()
}

@available(iOS 26.0, *)
#Preview("Active Timer") {
    TwentyTwentyLotusView(initialPhase: .activeTimer)
}
