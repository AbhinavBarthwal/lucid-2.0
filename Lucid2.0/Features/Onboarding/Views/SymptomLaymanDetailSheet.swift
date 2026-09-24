//
//  SymptomLaymanDetailSheet.swift
//  Lucid2.0
//
//  Created by Antigravity on 21/09/26.
//

import SwiftUI

public struct SymptomLaymanInfo: Identifiable, Sendable {
    public var id: String { name }
    public let name: String
    public let icon: String
    public let tagline: String
    public let laymanDescription: String
    public let whyScreensCauseIt: String
    public let howLucRelievesIt: String
    public let recommendedExerciseName: String

    public static let catalog: [String: SymptomLaymanInfo] = [
        "Digital Eye Strain": SymptomLaymanInfo(
            name: "Digital Eye Strain",
            icon: "display",
            tagline: "Fatigued, aching eyes after long screen sessions",
            laymanDescription: "When you stare at fixed-distance pixels for hours, the tiny ciliary focusing muscles inside your eyes stay clenched in a continuous isometric spasm, like holding a heavy weight without dropping it.",
            whyScreensCauseIt: "Computer and phone displays lack natural depth variation. Your eyes are forced into high-contrast accommodation with almost zero depth rest.",
            howLucRelievesIt: "Luc guides rapid depth-switching (20-20-20 rule) and near-far transitions that force the focusing muscle to release tension.",
            recommendedExerciseName: "Near Far Focus & 20-20-20 Reset"
        ),
        "Dry Eyes": SymptomLaymanInfo(
            name: "Dry Eyes",
            icon: "drop.fill",
            tagline: "Burning, stinging, or gritty sensation under eyelids",
            laymanDescription: "Your eyes naturally produce a lipid tear film to stay lubricated. When you concentrate on a screen, your subconscious blink rate drops by over 60%, leaving the surface exposed to air and drying out.",
            whyScreensCauseIt: "Intense visual focus causes 'incomplete blinks' where eyelids don't touch, starving the cornea of fresh moisture.",
            howLucRelievesIt: "Luc uses haptic vibration cues to train full, complete, rhythmic blinks that reactivate the meibomian oil glands and rebuild your tear layer.",
            recommendedExerciseName: "Blink Training Routine"
        ),
        "Blurry Vision": SymptomLaymanInfo(
            name: "Blurry Vision",
            icon: "eye.trianglebadge.exclamationmark",
            tagline: "Fuzzy sight when looking up across the room",
            laymanDescription: "Also called 'accommodative lockup' — your eye's focusing lens gets stuck in near mode and can't quickly relax when you glance across the room.",
            whyScreensCauseIt: "Holding static focal length for more than 45 minutes temporarily locks the lens capsule in an elongated state.",
            howLucRelievesIt: "Gentle smooth pursuits and infinity loops loosen the surrounding suspensory ligaments, speeding up focus transition time.",
            recommendedExerciseName: "Smooth Pursuits & Figure 8"
        ),
        "Eye Fatigue": SymptomLaymanInfo(
            name: "Eye Fatigue",
            icon: "moon.fill",
            tagline: "Heavy eyelids and difficulty keeping eyes open",
            laymanDescription: "The six external eye muscles (extraocular muscles) that steer your eyes get exhausted from micro-jittering to keep small typography aligned.",
            whyScreensCauseIt: "Reading dense text, code, or spreadsheets requires thousands of tiny saccadic jumps per minute, exhausting ocular stamina.",
            howLucRelievesIt: "Luc applies relaxing smooth tracking to gently stretch all six muscle pairs and restore oxygen-rich blood flow.",
            recommendedExerciseName: "Figure 8 Muscle Relaxation"
        ),
        "Headaches / Neck Pain": SymptomLaymanInfo(
            name: "Headaches / Neck Pain",
            icon: "figure.walk",
            tagline: "Tension behind the eyes radiating into the neck",
            laymanDescription: "Hunching towards screens ('tech neck') compresses the suboccipital nerves at the base of your skull, which send referred pain signals directly behind your eyes.",
            whyScreensCauseIt: "Every inch your head tilts forward doubles the effective weight your cervical spine must support.",
            howLucRelievesIt: "Real-time camera-guided neck rotations and chin tucks that decompress cervical vertebrae and release trapped blood vessels.",
            recommendedExerciseName: "Neck Mobility Routine"
        ),
        "Light Sensitivity": SymptomLaymanInfo(
            name: "Light Sensitivity",
            icon: "sun.max.fill",
            tagline: "Squinting or pain from bright screens and indoor glare",
            laymanDescription: "Your pupils and photoreceptors become hyper-sensitized when exposed to high-contrast white backgrounds in dimly lit rooms.",
            whyScreensCauseIt: "Extreme contrast ratios between screen brightness and surrounding room light overwhelm the pupillary reflex.",
            howLucRelievesIt: "Palming dark-rest drills that give photoreceptors complete rest, plus ambient lighting calibration reminders.",
            recommendedExerciseName: "Photoreceptor Dark Rest"
        ),
        "Astigmatism": SymptomLaymanInfo(
            name: "Astigmatism",
            icon: "circle.dotted",
            tagline: "Ghosting or slight shadows around text and symbols",
            laymanDescription: "Your cornea is shaped slightly like a football rather than a basketball, meaning light focuses on multiple points instead of one crisp spot.",
            whyScreensCauseIt: "Digital pixel matrices emphasize ghosting along edges, requiring your brain and eyes to work double-time to interpret blurry text.",
            howLucRelievesIt: "Fixation stability drills that train your visual cortex to track targets cleanly and reduce strain-induced blurring.",
            recommendedExerciseName: "Saccadic Jumps & Fixation"
        ),
        "Presbyopia": SymptomLaymanInfo(
            name: "Presbyopia",
            icon: "textformat.size",
            tagline: "Needing to push your phone further away to read",
            laymanDescription: "A natural stiffening of the crystalline lens inside your eye as we age, making it harder to snap into crisp near-focus.",
            whyScreensCauseIt: "Constantly zooming in or pushing devices away tires out the remaining flexibility of your lens fibers.",
            howLucRelievesIt: "Pushup convergence drills that maximize the muscular reserve of your ciliary body and near-point focus.",
            recommendedExerciseName: "Pencil Push-Up Drill"
        ),
        "Convergence Issues": SymptomLaymanInfo(
            name: "Convergence Issues",
            icon: "arrow.left.and.right",
            tagline: "Double vision or losing your place while reading lines",
            laymanDescription: "When looking up close, both eyes must aim inward towards your nose in unison. Weakened medial rectus muscles cause one eye to drift outward.",
            whyScreensCauseIt: "Fatigue from prolonged screen reading breaks down binocular coordination, causing words to swim or separate.",
            howLucRelievesIt: "Targeted convergence training (Pencil Pushups) to strengthen the inner eye muscles and lock in steady binocular alignment.",
            recommendedExerciseName: "Pencil Push-Up Convergence"
        )
    ]
}

public struct SymptomLaymanDetailSheet: View {
    public let info: SymptomLaymanInfo
    public var onDismiss: () -> Void

    public init(info: SymptomLaymanInfo, onDismiss: @escaping () -> Void) {
        self.info = info
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack(alignment: .top) {
            Color(red: 0.06, green: 0.08, blue: 0.14).ignoresSafeArea()

            VStack(spacing: 0) {
                // Drag Handle
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Palette.amber.opacity(0.15))
                                    .frame(width: 52, height: 52)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .strokeBorder(Palette.amber.opacity(0.35), lineWidth: 1)
                                    )

                                Image(systemName: info.icon)
                                    .font(Typography.title2(weight: .bold))
                                    .foregroundStyle(Palette.warmGradient)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(info.name)
                                    .font(Typography.title3(weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)

                                Text(info.tagline)
                                    .font(Typography.caption())
                                    .foregroundStyle(Color.white.opacity(0.6))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.top, 14)

                        // 1. Layman Definition Card
                        glassSectionCard(
                            icon: "info.circle.fill",
                            iconColor: Palette.amber,
                            title: "What is this?",
                            description: info.laymanDescription
                        )

                        // 2. Why Screens Trigger It
                        glassSectionCard(
                            icon: "display.trianglebadge.exclamationmark",
                            iconColor: Color.red.opacity(0.9),
                            title: "Why screens cause this",
                            description: info.whyScreensCauseIt
                        )

                        // 3. How Luc Helps
                        glassSectionCard(
                            icon: "sparkles",
                            iconColor: Palette.honey,
                            title: "How Luc relieves it",
                            description: info.howLucRelievesIt
                        )

                        // Recommended Drill Pill
                        HStack(spacing: 10) {
                            Image(systemName: "dumbbell.fill")
                                .font(Typography.footnote(weight: .semibold))
                                .foregroundStyle(Palette.amber)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Targeted Routine")
                                    .font(Typography.caption2(weight: .medium))
                                    .foregroundStyle(Color.white.opacity(0.5))
                                Text(info.recommendedExerciseName)
                                    .font(Typography.subheadline(weight: .semibold))
                                    .foregroundStyle(.white)
                            }

                            Spacer()
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                        )

                        // Dismiss Button
                        Button(action: onDismiss) {
                            Text("Got it")
                                .font(Typography.headline(weight: .bold))
                                .foregroundStyle(Color.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 44, style: .continuous)
                                        .fill(Palette.warmGradient)
                                        .glassEffect(.clear, in: .capsule)
                                        .shadow(color: Palette.ember.opacity(0.4), radius: 12, x: 0, y: 4)
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 6)
                        .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
    }

    private func glassSectionCard(icon: String, iconColor: Color, title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(Typography.footnote(weight: .bold))
                    .foregroundStyle(iconColor)

                Text(title)
                    .font(Typography.subheadline(weight: .bold))
                    .foregroundStyle(.white)
            }

            Text(description)
                .font(Typography.footnote())
                .foregroundStyle(Color.white.opacity(0.78))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground(top: Palette.cardTop, bottom: Palette.cardBottom, corner: 18)
    }
}
