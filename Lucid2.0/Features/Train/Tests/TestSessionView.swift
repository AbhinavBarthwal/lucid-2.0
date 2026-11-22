//
//  TestSessionView.swift
//  Lucid2.0
//
//  Real, interactive vision test sessions: hosts the storyboard-backed
//  LandoltCViewController (ring-orientation acuity, spoken answers) and
//  OSDIViewController (12-item dry-eye questionnaire) via UIViewControllerRepresentable,
//  the same pattern used for the legacy exercise storyboards.
//

import SwiftUI
import UIKit

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
                LandoltCTestRepresentable(onCompleted: handleLandoltFinished)
                    .ignoresSafeArea()
            case .osdi:
                OSDITestRepresentable(onCompleted: handleOSDIFinished)
                    .ignoresSafeArea()
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

    private func handleLandoltFinished(leftPoints: Int, rightPoints: Int) {
        // LucidScoreEngine.recordTestResults(cTestAcuity:) normalizes against a 0-6 scale
        // (acuity / 6.0) — the same 0-6 Snellen point system each eye is graded on here.
        let score = Double(leftPoints + rightPoints) / 2.0
        cTestScore = score
        switch mode {
        case .single(let test):
            TestScheduleManager.shared.completeTest(id: test.id, score: score)
            withAnimation { stage = .finished }
        case .battery:
            withAnimation { stage = .osdi }
        }
    }

    private func handleOSDIFinished(score: Double, severity: String) {
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

// MARK: - UIKit hosts

private struct LandoltCTestRepresentable: UIViewControllerRepresentable {
    let onCompleted: (Int, Int) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIStoryboard(name: "LandoltC", bundle: nil).instantiateInitialViewController()
        (vc as? LandoltCViewController)?.onTestCompleted = onCompleted
        return vc ?? UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        (uiViewController as? LandoltCViewController)?.onTestCompleted = onCompleted
    }
}

private struct OSDITestRepresentable: UIViewControllerRepresentable {
    let onCompleted: (Double, String) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIStoryboard(name: "OSDI", bundle: nil).instantiateInitialViewController()
        (vc as? OSDIViewController)?.onTestCompleted = onCompleted
        return vc ?? UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        (uiViewController as? OSDIViewController)?.onTestCompleted = onCompleted
    }
}

#Preview("Battery") {
    TestSessionView(mode: .battery, onDismiss: {})
}

#Preview("Single - OSDI") {
    TestSessionView(mode: .single(.osdi), onDismiss: {})
}
