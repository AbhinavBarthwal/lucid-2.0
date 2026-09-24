//
//  ExerciseSessionView.swift
//  Lucid2.0
//
//  SwiftUI wrapper that hosts legacy UIKit Storyboard exercises
//  and bridges their lifecycle and completion events to SwiftUI.
//  Presents an animated shade reveal transition on entry.
//

import SwiftUI
import UIKit

public struct ExerciseSessionView: View {
    public let exercise: ExerciseDefinition
    public let onCompleted: () -> Void
    public let onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var hasTriggeredCompletion = false
    @State private var showShadeReveal = true

    public init(
        exercise: ExerciseDefinition,
        onCompleted: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.exercise = exercise
        self.onCompleted = onCompleted
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            LegacyExerciseRepresentable(
                exercise: exercise,
                onCompleted: {
                    guard !hasTriggeredCompletion else { return }
                    hasTriggeredCompletion = true
                    onCompleted()
                },
                onDismiss: {
                    onDismiss()
                }
            )
            .ignoresSafeArea()

            // Close / Exit button overlay
            Button {
                onDismiss()
                dismiss()
            } label: {
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

            // Animated shade rolling up / revealing the session
            if showShadeReveal {
                ExerciseShadeTransitionView(
                    exercise: exercise,
                    mode: .reveal,
                    onRevealed: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showShadeReveal = false
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .legacyExerciseDidComplete)) { _ in
            guard !hasTriggeredCompletion else { return }
            hasTriggeredCompletion = true
            onCompleted()
            dismiss()
        }
    }
}

// MARK: - UIKit Host Representable
private struct LegacyExerciseRepresentable: UIViewControllerRepresentable {
    let exercise: ExerciseDefinition
    let onCompleted: () -> Void
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = instantiateExerciseViewController(for: exercise)
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No dynamic updates needed while running UIKit exercise
    }

    private func instantiateExerciseViewController(for exercise: ExerciseDefinition) -> UIViewController {
        switch exercise.id {
        case "smooth_pursuits":
            if let vc = UIStoryboard(name: "SmoothPursits", bundle: nil).instantiateInitialViewController() {
                return vc
            }
            return UIStoryboard(name: "SmoothPursits", bundle: nil).instantiateViewController(withIdentifier: "SmoothPursuitsVC")

        case "saccadic_jumps":
            if let vc = UIStoryboard(name: "SaccadicJumps", bundle: nil).instantiateInitialViewController() {
                return vc
            }
            return UIStoryboard(name: "SaccadicJumps", bundle: nil).instantiateViewController(withIdentifier: "SaccadicJumpsVC")

        case "figure_8":
            if let vc = UIStoryboard(name: "FigureEight", bundle: nil).instantiateInitialViewController() {
                return vc
            }
            return UIStoryboard(name: "FigureEight", bundle: nil).instantiateViewController(withIdentifier: "FigureEightVC")

        case "pencil_pushup":
            if let vc = UIStoryboard(name: "PencilPushUp", bundle: nil).instantiateInitialViewController() {
                return vc
            }
            return UIStoryboard(name: "PencilPushUp", bundle: nil).instantiateViewController(withIdentifier: "PencilPushUpVC")

        case "peripheral_awareness":
            if let vc = UIStoryboard(name: "PeripheralAwareness", bundle: nil).instantiateInitialViewController() {
                return vc
            }
            return UIStoryboard(name: "PeripheralAwareness", bundle: nil).instantiateViewController(withIdentifier: "PeripheralVC")

        case "blink_training":
            if let vc = UIStoryboard(name: "BlinkTraining", bundle: nil).instantiateInitialViewController() {
                return vc
            }
            return UIStoryboard(name: "BlinkTraining", bundle: nil).instantiateViewController(withIdentifier: "BlinkTrainingVC")

        case "near_far_focus":
            if let vc = UIStoryboard(name: "NearFarFocus", bundle: nil).instantiateInitialViewController() {
                return vc
            }
            return UIStoryboard(name: "NearFarFocus", bundle: nil).instantiateViewController(withIdentifier: "NearFarFocusVC")

        default:
            break
        }

        // Fallback placeholder if no storyboard matches
        let fallbackVC = UIViewController()
        fallbackVC.view.backgroundColor = .black
        let label = UILabel()
        label.text = "\(exercise.title) Session"
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 22)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        fallbackVC.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: fallbackVC.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: fallbackVC.view.centerYAnchor)
        ])
        return fallbackVC
    }
}
