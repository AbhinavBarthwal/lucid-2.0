//
//  TestSessionView.swift
//  Lucid2.0
//
//  Real, interactive vision test sessions: a Landolt-C ring-orientation
//  acuity test and a 12-item OSDI dry-eye questionnaire with real scoring,
//  replacing the previous placeholder/instant-fake-completion flow.
//

import SwiftUI

public enum TestSessionMode {
    /// Run a single test (from the Train tab's Vision Tests section) and record just that score.
    case single(TestDefinition)
    /// Run the full battery (Landolt-C then OSDI) back to back — used by the Home "Start Test" card.
    case battery
}

public struct TestSessionView: View {
    public let mode: TestSessionMode
    public let onDismiss: () -> Void

    @State private var stage: Stage
    @State private var cTestScore: Double?
    @State private var osdiScore: Double?

    private enum Stage {
        case landoltC
        case osdi
        case finished
    }

    public init(mode: TestSessionMode, onDismiss: @escaping () -> Void) {
        self.mode = mode
        self.onDismiss = onDismiss
        switch mode {
        case .single(let test):
            _stage = State(initialValue: test.id == "osdi" ? .osdi : .landoltC)
        case .battery:
            _stage = State(initialValue: .landoltC)
        }
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            Color(red: 0.05, green: 0.06, blue: 0.12).ignoresSafeArea()

            switch stage {
            case .landoltC:
                LandoltCFlowView(onFinished: handleLandoltFinished)
            case .osdi:
                OSDIFlowView(onFinished: handleOSDIFinished)
            case .finished:
                finishedCard
            }

            closeButton
        }
        .preferredColorScheme(.dark)
    }

    private var closeButton: some View {
        Button(action: onDismiss) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.45))
                    .glassEffect(.clear, in: .circle)
                    .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 0.8))
                    .frame(width: 36, height: 36)
                Image(systemName: "xmark")
                    .font(Typography.subheadline(weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(16)
        }
        .buttonStyle(.plain)
    }

    private func handleLandoltFinished(_ score: Double) {
        cTestScore = score
        switch mode {
        case .single(let test):
            TestScheduleManager.shared.completeTest(id: test.id, score: score)
            withAnimation { stage = .finished }
        case .battery:
            withAnimation { stage = .osdi }
        }
    }

    private func handleOSDIFinished(_ score: Double) {
        osdiScore = score
        switch mode {
        case .single(let test):
            TestScheduleManager.shared.completeTest(id: test.id, score: score)
            withAnimation { stage = .finished }
        case .battery:
            TestScheduleManager.shared.completeTestBattery(
                cTestScore: cTestScore ?? TestScheduleManager.shared.lastCTestScore,
                osdiScore: score
            )
            withAnimation { stage = .finished }
        }
    }

    private var finishedCard: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 54, weight: .bold))
                .foregroundStyle(Palette.warmGradient)

            Text("Results Saved")
                .font(Typography.title2(weight: .bold))
                .foregroundStyle(.white)

            Text("Your vision score has been updated.")
                .font(Typography.subheadline())
                .foregroundStyle(Color.white.opacity(0.7))

            Button(action: onDismiss) {
                Text("Done")
                    .font(Typography.headline(weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 50)
                    .background(Capsule().fill(Palette.warmGradient))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 40)
            .padding(.top, 8)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Landolt-C Acuity Test

private enum LandoltDirection: CaseIterable {
    case right, down, left, up

    var rotationDegrees: Double {
        switch self {
        case .right: return 0
        case .down: return 90
        case .left: return 180
        case .up: return 270
        }
    }

    var symbolName: String {
        switch self {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .left: return "arrow.left"
        case .right: return "arrow.right"
        }
    }

    var label: String {
        switch self {
        case .up: return "Up"
        case .down: return "Down"
        case .left: return "Left"
        case .right: return "Right"
        }
    }
}

private struct LandoltCShape: Shape {
    func path(in rect: CGRect) -> Path {
        Circle().trim(from: 0, to: 0.86).path(in: rect)
    }
}

private struct LandoltCTrial {
    let eye: Eye
    let size: CGFloat
    let direction: LandoltDirection

    enum Eye: String { case left = "Left", right = "Right" }
}

private struct LandoltCFlowView: View {
    let onFinished: (_ score: Double) -> Void

    @State private var trials: [LandoltCTrial] = LandoltCFlowView.makeTrials()
    @State private var currentIndex = 0
    @State private var correctCount = 0
    @State private var feedback: Bool?
    @State private var showEyeInstruction = true

    static func makeTrials() -> [LandoltCTrial] {
        let sizes: [CGFloat] = [130, 108, 86, 64, 48]
        var result: [LandoltCTrial] = []
        for eye in [LandoltCTrial.Eye.right, .left] {
            var lastDirection: LandoltDirection?
            for size in sizes {
                var direction = LandoltDirection.allCases.randomElement()!
                while direction == lastDirection {
                    direction = LandoltDirection.allCases.randomElement()!
                }
                lastDirection = direction
                result.append(LandoltCTrial(eye: eye, size: size, direction: direction))
            }
        }
        return result
    }

    private var currentTrial: LandoltCTrial? {
        trials.indices.contains(currentIndex) ? trials[currentIndex] : nil
    }

    private var isFirstTrialOfEye: Bool {
        guard let trial = currentTrial else { return false }
        if currentIndex == 0 { return true }
        return trials[currentIndex - 1].eye != trial.eye
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 40)

            if let trial = currentTrial {
                VStack(spacing: 6) {
                    Text("Visual Acuity")
                        .font(Typography.caption2(weight: .bold))
                        .foregroundStyle(Palette.amber)
                        .kerning(1.2)
                    Text("Trial \(currentIndex + 1) of \(trials.count)")
                        .font(Typography.title3(weight: .bold))
                        .foregroundStyle(.white)
                    Text("\(trial.eye.rawValue) Eye — cover your other eye")
                        .font(Typography.subheadline())
                        .foregroundStyle(Color.white.opacity(0.6))
                }

                Spacer()

                LandoltCShape()
                    .stroke(style: StrokeStyle(lineWidth: trial.size * 0.22, lineCap: .butt))
                    .frame(width: trial.size, height: trial.size)
                    .rotationEffect(.degrees(trial.direction.rotationDegrees))
                    .foregroundStyle(.white)
                    .animation(.easeInOut(duration: 0.2), value: currentIndex)

                Spacer()

                Text("Which way does the gap open?")
                    .font(Typography.subheadline(weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.75))

                directionPad

                if let feedback {
                    Label(feedback ? "Correct" : "Not quite", systemImage: feedback ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(Typography.subheadline(weight: .bold))
                        .foregroundStyle(feedback ? .green : .orange)
                }
            } else {
                ProgressView()
            }

            Spacer(minLength: 60)
        }
        .padding(.horizontal, 24)
        .alert("Testing \(currentTrial?.eye.rawValue ?? "") Eye", isPresented: $showEyeInstruction) {
            Button("Ready") {}
        } message: {
            Text("Hold your device at arm's length and cover your \(currentTrial?.eye == .right ? "left" : "right") eye.")
        }
    }

    private var directionPad: some View {
        VStack(spacing: 10) {
            directionButton(.up)
            HStack(spacing: 10) {
                directionButton(.left)
                directionButton(.right)
            }
            directionButton(.down)
        }
    }

    private func directionButton(_ direction: LandoltDirection) -> some View {
        Button {
            answer(direction)
        } label: {
            Image(systemName: direction.symbolName)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.white.opacity(0.08)))
                .overlay(Circle().strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(feedback != nil)
    }

    private func answer(_ direction: LandoltDirection) {
        guard let trial = currentTrial, feedback == nil else { return }
        let isCorrect = direction == trial.direction
        if isCorrect { correctCount += 1 }
        feedback = isCorrect

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            feedback = nil
            if currentIndex + 1 < trials.count {
                currentIndex += 1
                if isFirstTrialOfEye { showEyeInstruction = true }
            } else {
                let score = (Double(correctCount) / Double(trials.count)) * 10.0
                onFinished(score)
            }
        }
    }
}

// MARK: - OSDI Dry Eye Questionnaire

private struct OSDIQuestion {
    let text: String
}

private struct OSDIFlowView: View {
    let onFinished: (_ score: Double) -> Void

    private let questions: [OSDIQuestion] = [
        OSDIQuestion(text: "Eyes that are sensitive to light?"),
        OSDIQuestion(text: "Eyes that feel gritty?"),
        OSDIQuestion(text: "Painful or sore eyes?"),
        OSDIQuestion(text: "Blurred vision?"),
        OSDIQuestion(text: "Poor vision in general?"),
        OSDIQuestion(text: "Problems with reading?"),
        OSDIQuestion(text: "Problems driving at night?"),
        OSDIQuestion(text: "Problems using a computer or phone screen?"),
        OSDIQuestion(text: "Problems watching TV?"),
        OSDIQuestion(text: "Discomfort in windy conditions?"),
        OSDIQuestion(text: "Discomfort in low-humidity (dry) places?"),
        OSDIQuestion(text: "Discomfort in air-conditioned areas?")
    ]

    private let options: [(label: String, value: Int)] = [
        ("None of the time", 0),
        ("Some of the time", 1),
        ("Half of the time", 2),
        ("Most of the time", 3),
        ("All of the time", 4)
    ]

    @State private var currentIndex = 0
    @State private var scores: [Int] = []

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 40)

            VStack(spacing: 6) {
                Text("Dry Eye Check")
                    .font(Typography.caption2(weight: .bold))
                    .foregroundStyle(Palette.amber)
                    .kerning(1.2)
                Text("Question \(currentIndex + 1) of \(questions.count)")
                    .font(Typography.subheadline())
                    .foregroundStyle(Color.white.opacity(0.6))
            }

            ProgressView(value: Double(currentIndex), total: Double(questions.count))
                .tint(Palette.amber)
                .padding(.horizontal, 24)

            Text("During the past week, how often have you had:")
                .font(Typography.subheadline())
                .foregroundStyle(Color.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Text(questions[currentIndex].text)
                .font(Typography.title3(weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 10) {
                ForEach(options, id: \.value) { option in
                    Button {
                        answer(option.value)
                    } label: {
                        Text(option.label)
                            .font(Typography.subheadline(weight: .medium))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.white.opacity(0.06))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 60)
        }
    }

    private func answer(_ value: Int) {
        scores.append(value)
        if currentIndex + 1 < questions.count {
            currentIndex += 1
        } else {
            let maxPossible = Double(questions.count * 4)
            let total = Double(scores.reduce(0, +))
            let osdiScore = (total * 100.0) / maxPossible
            onFinished(osdiScore)
        }
    }
}

#Preview("Battery") {
    TestSessionView(mode: .battery, onDismiss: {})
}

#Preview("Single - OSDI") {
    TestSessionView(mode: .single(.osdi), onDismiss: {})
}
