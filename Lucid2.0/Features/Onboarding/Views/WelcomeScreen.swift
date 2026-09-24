import SwiftUI

// MARK: - Slide Step Model (3 Pages: Strain, Philosophy, Meet Luc)
enum OnboardingStep: Int, CaseIterable {
    case strain = 0      // Page 1: Screen strain problem
    case personal = 1    // Page 2: Philosophy (Shift Phase 1)
    case meetLuc = 2     // Page 3: Luc Mascot & Tailored Plan (Shift Phase 2)

    var isLastStep: Bool {
        self == .meetLuc
    }

    var ambientColor: Color {
        switch self {
        case .strain:
            return Color(red: 0.35, green: 0.12, blue: 0.16)
        case .personal:
            return Color(red: 0.26, green: 0.14, blue: 0.34)
        case .meetLuc:
            return Color(red: 0.12, green: 0.35, blue: 0.22)
        }
    }
}

public struct OnboardingView: View {
    public var onUnlock: (() -> Void)? = nil

    @State private var step: OnboardingStep = .strain

    public init(onUnlock: (() -> Void)? = nil) {
        self.onUnlock = onUnlock
    }

    // Silky kinetic slide transition for step changes
    private var fullSlideTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity
                .combined(with: .offset(y: 20))
                .combined(with: .scale(scale: 0.98)),
            removal: .opacity
                .combined(with: .offset(y: -16))
        )
    }

    // Previous text fades away instead of sliding
    private var personalSlideTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity
                .combined(with: .offset(y: 20))
                .combined(with: .scale(scale: 0.98)),
            removal: .opacity
        )
    }

    public var body: some View {
        ZStack {
            // OLED Pure Dark Background
            Color.black.ignoresSafeArea()

            // Dynamic bottom ambient radial glow
            GeometryReader { proxy in
                VStack {
                    Spacer()
                    RadialGradient(
                        colors: [
                            step.ambientColor.opacity(0.85),
                            step.ambientColor.opacity(0.28),
                            Color.clear
                        ],
                        center: .bottom,
                        startRadius: 35,
                        endRadius: proxy.size.width * 2
                    )
                    .frame(height: proxy.size.height * 0.65)
                    .blur(radius: 50)
                }
            }
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.85), value: step)

            // Mascot Hero Layer (Luc appears big, comes from bottom of screen to thoda upar of middle)
            GeometryReader { proxy in
                if step == .meetLuc {
                    LucMascotHeroView(screenSize: proxy.size)
                        .transition(.opacity)
                }
            }
            .ignoresSafeArea()

            // Main Content Layout
            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                // Animated Content Container
                ZStack(alignment: .bottomLeading) {
                    switch step {
                    case .strain:
                        strainSlide
                            .transition(fullSlideTransition)

                    case .personal:
                        personalSlide
                            .transition(personalSlideTransition)

                    case .meetLuc:
                        MeetLucBottomTextView()
                            .transition(
                                .asymmetric(
                                    insertion: .opacity,
                                    removal: .opacity.combined(with: .offset(y: -16))
                                )
                            )
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)

                // Bottom Action Pill Button ("Unlock Lucid" on Meet Luc)
                bottomActionButton
                    .padding(.horizontal, 28)
                    .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Slide 1: Screen Strain
    private var strainSlide: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("Your")
                    .foregroundStyle(Color(white: 0.92))
                Image(systemName: "eye.fill")
                    .font(Typography.title2(weight: .bold))
                    .foregroundStyle(Color(red: 0.95, green: 0.42, blue: 0.42))
                Text("eyes")
                    .foregroundStyle(Color(white: 0.92))
            }

            Text("are constantly")
                .foregroundStyle(Color(white: 0.55))

            HStack(spacing: 8) {
                Text("strained")
                    .foregroundStyle(Color(red: 0.96, green: 0.52, blue: 0.52))
                Text("by the")
                    .foregroundStyle(Color(white: 0.55))
            }

            HStack {
                Image(systemName: "display")
                    .font(Typography.title2(weight: .bold))
                    .foregroundStyle(Color(red: 0.68, green: 0.78, blue: 0.95))
                Text("screens")
                    .foregroundStyle(Color(white: 0.92))
            }
            Text("around you.")
                .foregroundStyle(Color(white: 0.55))
        }
        .font(Typography.largeTitle(weight: .bold, design: .rounded))
    }

    // MARK: - Slide 2: Philosophy / Personal Problem
    private var personalSlide: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                Text("To fix that !!!")
                    .foregroundStyle(Color(white: 0.58))
                Text("Let us not do some")
                    .foregroundStyle(Color(white: 0.58))

                HStack(spacing: 8) {
                    Text("random")
                    Image(systemName: "shuffle")
                        .font(Typography.title3(weight: .bold))
                    Text("exercises.")
                }
                .foregroundStyle(Color(white: 0.58))

                Spacer().frame(height: 20)

                HStack(spacing: 8) {
                    Text("Everyone needs")
                }
                .foregroundStyle(Color(white: 0.58))

                HStack(spacing: 8) {
                    Text("something")
                        .foregroundStyle(Color.white)
                    Image(systemName: "sparkles")
                        .font(Typography.title3(weight: .bold))
                        .foregroundStyle(Color.yellow)

                    Text("unique")
                        .foregroundStyle(Color.white)
                    Text(" to")
                        .foregroundStyle(Color(white: 0.58))
                }

                Text("their problem")
                    .foregroundStyle(Color(white: 0.58))
            }
            .font(Typography.largeTitle(weight: .bold, design: .rounded))
        }
    }

    // MARK: - Bottom Action Pill Button
    private var bottomActionButton: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

            if step.isLastStep {
                onUnlock?()
            } else {
                withAnimation(.spring(response: 0.58, dampingFraction: 0.84)) {
                    if let next = OnboardingStep(rawValue: step.rawValue + 1) {
                        step = next
                    } else {
                        step = .strain
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                if step.isLastStep {
                    Image(systemName: "lock.open.fill")
                        .font(Typography.subheadline(weight: .bold))
                        .transition(.scale.combined(with: .opacity))
                }
                Text(step.isLastStep ? "Unlock Lucid" : "Next")
                    .font(Typography.headline(weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 54)
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .glassEffect(.clear, in: .capsule)
                    .overlay(
                        Capsule()
                            .stroke(
                                step.isLastStep
                                    ? Color(red: 0.52, green: 0.92, blue: 0.68).opacity(0.45)
                                    : Color.white.opacity(0.14),
                                lineWidth: step.isLastStep ? 1.5 : 1.2
                            )
                    )
            }
            .shadow(
                color: step.isLastStep
                    ? Color(red: 0.52, green: 0.92, blue: 0.68).opacity(0.25)
                    : Color.clear,
                radius: 12,
                y: 4
            )
        }
    }
}

// MARK: - Luc Mascot Hero View (Big Animated Mascot)
struct LucMascotHeroView: View {
    let screenSize: CGSize

    @State private var lucAppeared: Bool = false
    @State private var isFloating: Bool = false

    public var body: some View {
        let lucSize = screenSize.width * 1.5
        // Screen center is screenSize.height * 0.5
        // "thoda upar" of the middle of the screen: ~0.37
        let targetY = screenSize.height * 0.37
        let startY = screenSize.height + (lucSize * 0.55)

        ZStack {
            // Ambient soft warm radial glow radiating behind Luc
            RadialGradient(
                colors: [
                    Color(red: 0.98, green: 0.58, blue: 0.18).opacity(0.35),
                    Color(red: 0.12, green: 0.35, blue: 0.22).opacity(0.18),
                    Color.clear
                ],
                center: .center,
                startRadius: 20,
                endRadius: lucSize * 0.42
            )
            .frame(width: lucSize, height: lucSize)
            .scaleEffect(lucAppeared ? 1.0 : 0.4)
            .opacity(lucAppeared ? 1.0 : 0.0)

            // Big Luc Mascot Image emerging from the bottom
            Image("Luc")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: lucSize, height: lucSize)
                .shadow(color: Color(red: 0.98, green: 0.55, blue: 0.20).opacity(0.35), radius: 30, x: 0, y: 12)
        }
        .position(
            x: screenSize.width / 2,
            y: lucAppeared ? (targetY + (isFloating ? -7 : 7)) : startY
        )
        .onAppear {
            lucAppeared = false
            isFloating = false

            // Luc emerges from the bottom of the screen to slightly above the middle
            withAnimation(.spring(response: 0.86, dampingFraction: 0.74, blendDuration: 0)) {
                lucAppeared = true
            }

            // Gentle floating loop after arrival
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.92) {
                withAnimation(.easeInOut(duration: 2.3).repeatForever(autoreverses: true)) {
                    isFloating = true
                }
            }
        }
        .onDisappear {
            lucAppeared = false
            isFloating = false
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Slide 3: Bottom Text Reveal for Luc
struct MeetLucBottomTextView: View {
    private let mintHighlight = Color(red: 0.82, green: 0.94, blue: 0.84)
    @State private var textRevealed: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 2) {
                Text("Meet")
                    .foregroundStyle(mintHighlight)
                Text(" LUC")
                    .foregroundStyle(.white)
            }
            .font(Typography.title(weight: .bold, design: .rounded))

            VStack(alignment: .leading, spacing: 14) {
                Text("He will get you, your")
                    .foregroundStyle(mintHighlight)

                HStack(spacing: 8) {
                    Text("personalized plan")
                        .foregroundStyle(mintHighlight)
                    Image(systemName: "wand.and.stars")
                        .font(Typography.title2(weight: .bold))
                        .foregroundStyle(mintHighlight)
                }
            }
            .font(Typography.title(weight: .bold, design: .rounded))
        }
        .opacity(textRevealed ? 1 : 0)
        .offset(y: textRevealed ? 0 : 26)
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.82).delay(0.42)) {
                textRevealed = true
            }
        }
        .onDisappear {
            textRevealed = false
        }
    }
}

#Preview {
    OnboardingView()
        .preferredColorScheme(.dark)
}
