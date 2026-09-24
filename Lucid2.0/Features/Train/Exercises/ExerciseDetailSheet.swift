//
//  ExerciseDetailSheet.swift
//  Lucid2.0
//
//  Bottom sheet shown when a user taps an exercise card.
//
//  Flow:
//  - First time: shows an info blurb, then "Show Instructions" + "Start Exercise"
//  - Returning:  shows "Show Instructions" (ghost) + "Start Exercise" (primary CTA)
//  - Camera gate: for requiresCamera exercises, checks AVCaptureDevice permission before starting
//

import SwiftUI
import AVFoundation
import UIKit

public struct ExerciseDetailSheet: View {
    public let exercise: ExerciseDefinition
    public var onStart: () -> Void
    public var onDismiss: () -> Void

    @State private var isFirstRun: Bool
    @State private var showCameraAlert = false
    @State private var showSettingsAlert = false
    @State private var hasShownInstructions = false

    public init(
        exercise: ExerciseDefinition,
        onStart: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.exercise = exercise
        self.onStart = onStart
        self.onDismiss = onDismiss
        self._isFirstRun = State(initialValue: ExerciseInstructionTracker.shared.isFirstRun(for: exercise.id))
    }

    public var body: some View {
        ZStack(alignment: .top) {
            // Background
            Color(red: 0.05, green: 0.06, blue: 0.12).ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Hero Image
                ZStack(alignment: .bottomLeading) {
                    Image(exercise.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 240)
                        .clipped()

                    // Bottom fade
                    LinearGradient(
                        colors: [.clear, Color(red: 0.05, green: 0.06, blue: 0.12)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 120)
                    .frame(maxWidth: .infinity, alignment: .bottom)
                }
                .frame(height: 240)

                // MARK: - Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        // Title + Duration
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.title)
                                    .font(Typography.title2(weight: .bold))
                                    .foregroundStyle(.white)

                                Text(exercise.subtitle)
                                    .font(Typography.subheadline())
                                    .foregroundStyle(Color.white.opacity(0.6))
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            // Duration badge
                            VStack(spacing: 3) {
                                Image(systemName: "clock.fill")
                                    .font(Typography.title3())
                                    .foregroundStyle(Palette.amber)
                                Text(exercise.durationMinutesFormatted)
                                    .font(Typography.caption(weight: .semibold))
                                    .foregroundStyle(Palette.amber)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Palette.amber.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .strokeBorder(Palette.amber.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }

                        // Camera requirement badge
                        if exercise.requiresCamera {
                            HStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(Typography.caption(weight: .semibold))
                                    .foregroundStyle(Color.white.opacity(0.7))
                                Text("Uses front camera for real-time eye tracking")
                                    .font(Typography.caption())
                                    .foregroundStyle(Color.white.opacity(0.6))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                        }

                        // MARK: - First-time info blurb
                        if isFirstRun && !hasShownInstructions {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 6) {
                                    Image(systemName: "lightbulb.fill")
                                        .font(Typography.footnote())
                                        .foregroundStyle(Palette.amber)
                                    Text("How it works")
                                        .font(Typography.footnote(weight: .semibold))
                                        .foregroundStyle(Palette.amber)
                                }

                                Text(exerciseInfoBlurb)
                                    .font(Typography.callout())
                                    .foregroundStyle(Color.white.opacity(0.75))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .lineSpacing(3)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Palette.amber.opacity(0.07))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .strokeBorder(Palette.amber.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }

                        // MARK: - Action Buttons
                        VStack(spacing: 12) {
                            // Primary: Start Exercise
                            Button(action: handleStartExercise) {
                                HStack(spacing: 8) {
                                    Text("Start Exercise")
                                        .font(Typography.headline(weight: .bold))
                                        .foregroundStyle(Color.black)
                                    Image(systemName: "arrow.right")
                                        .font(Typography.subheadline(weight: .bold))
                                        .foregroundStyle(Color.black)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 52)
                                .background(
                                    RoundedRectangle(cornerRadius: 44, style: .continuous)
                                        .fill(Palette.warmGradient)
                                        .glassEffect(.clear, in: .capsule)
                                        .shadow(color: Palette.ember.opacity(0.4), radius: 14, x: 0, y: 6)
                                )
                            }
                            .buttonStyle(.plain)

                            // Secondary: Show Instructions
                            Button(action: handleShowInstructions) {
                                HStack(spacing: 6) {
                                    Image(systemName: "play.circle")
                                        .font(Typography.subheadline())
                                    Text(isFirstRun && !hasShownInstructions ? "Show Instructions First" : "Show Instructions")
                                        .font(Typography.subheadline(weight: .medium))
                                }
                                .foregroundStyle(Color.white.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 44, style: .continuous)
                                        .fill(Color.white.opacity(0.06))
                                        .glassEffect(.clear, in: .capsule)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 44, style: .continuous)
                                                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 18)
                    .padding(.bottom, 48)
                }
            }

            // Close / drag handle
            Capsule()
                .fill(Color.white.opacity(0.2))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
        }
        .alert("Camera Access Required", isPresented: $showCameraAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This exercise uses the front camera for real-time eye tracking. Please enable Camera access in Settings to continue.")
        }
    }

    // MARK: - Helpers

    private var exerciseInfoBlurb: String {
        switch exercise.id {
        case "smooth_pursuits":
            return "A dot will move slowly across your screen. Keep your eyes on it without moving your head. The camera tracks whether you're following correctly."
        case "saccadic_jumps":
            return "Your eyes will jump quickly between targets that flash on screen. This builds the fast-twitch muscles used for reading and scanning."
        case "blink_training":
            return "You'll feel haptic pulses as cues. Blink both eyes together when prompted, then alternate left and right. A natural rhythm builds tear flow."
        case "neck_mobility":
            return "The camera guides you through gentle neck rotations. You'll move your head side to side, up and down — releasing tension from screen posture."
        case "near_far_focus":
            return "Hold your phone at arm's length, then bring it slowly close to your nose. Alternating focus distances prevents eye muscles from locking up."
        case "figure_8":
            return "Without moving your head, trace a big figure-8 in front of you with your eyes. This deeply stretches and relaxes all six eye muscles."
        case "pencil_pushup":
            return "Hold a finger in front of you and slowly bring it toward your nose until it goes double. This trains convergence — the muscle used for up-close focus."
        default:
            return "Follow the on-screen instructions to complete this exercise. Take breaks if you feel discomfort."
        }
    }

    private func handleShowInstructions() {
        // Mark instructions as seen once user taps this
        hasShownInstructions = true
        ExerciseInstructionTracker.shared.markSeen(for: exercise.id)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isFirstRun = false
        }
        // In a future iteration, this would launch a video player
        // For now it collapses the info blurb (confirming they've read it)
    }

    private func handleStartExercise() {
        if exercise.requiresCamera {
            checkCameraPermission { granted in
                if granted {
                    ExerciseInstructionTracker.shared.markSeen(for: exercise.id)
                    onStart()
                }
            }
        } else {
            ExerciseInstructionTracker.shared.markSeen(for: exercise.id)
            onStart()
        }
    }

    private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        case .denied, .restricted:
            showCameraAlert = true
            completion(false)
        @unknown default:
            completion(false)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ExerciseDetailSheet(
            exercise: .smoothPursuits,
            onStart: {},
            onDismiss: {}
        )
    }
}
