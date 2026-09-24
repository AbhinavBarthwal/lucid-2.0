//
//  OnboardingFlowCoordinator.swift
//  Lucid2.0
//
//  Created by Antigravity on 21/09/26.
//

import SwiftUI
import AuthenticationServices

public enum OnboardingPhase: Equatable {
    case welcome
    case account
    case personal
    case screenTime
    case eyePower
    case conditions
    case generatingPlan
    case planReveal
}

public struct OnboardingFlowCoordinator: View {
    public var onFinished: () -> Void

    @State private var phase: OnboardingPhase = .welcome
    @State private var profile = UserProfile()
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isExistingUser = false
    @State private var isPasswordPhase = false
    @State private var isCheckingUser = false
    @State private var errorMessage: String? = nil
    @State private var planBlueprint: PersonalizedPlanBlueprint?

    public init(onFinished: @escaping () -> Void) {
        self.onFinished = onFinished
    }

    // Dynamic ambient glow color for each onboarding phase
    private var phaseAmbientColor: Color {
        switch phase {
        case .welcome:
            return Color(red: 0.12, green: 0.35, blue: 0.22) // Matches Meet Luc green
        case .account:
            return Color(red: 0.16, green: 0.14, blue: 0.38) // Deep indigo / royal purple
        case .personal:
            return Color(red: 0.35, green: 0.20, blue: 0.08) // Warm amber / golden glow
        case .screenTime:
            return Color(red: 0.10, green: 0.20, blue: 0.42) // Digital blue / sapphire
        case .eyePower:
            return Color(red: 0.08, green: 0.28, blue: 0.30) // Optical teal / aqua
        case .conditions:
            return Color(red: 0.28, green: 0.14, blue: 0.32) // Amethyst / plum
        case .generatingPlan:
            return Color(red: 0.40, green: 0.18, blue: 0.06) // Glowing ember
        case .planReveal:
            return Color(red: 0.12, green: 0.32, blue: 0.22) // Emerald vitality & health
        }
    }

    public var body: some View {
        ZStack {
            // OLED Pure Dark Background
            Color.black.ignoresSafeArea()

            // Dynamic bottom ambient radial glow across onboarding pages
            GeometryReader { proxy in
                VStack {
                    Spacer()
                    RadialGradient(
                        colors: [
                            phaseAmbientColor.opacity(0.85),
                            phaseAmbientColor.opacity(0.28),
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
            .animation(.easeInOut(duration: 0.85), value: phase)

            VStack(spacing: 0) {
                // Top Navigation Bar (Shown on post-unlock steps)
                if phase != .welcome && phase != .generatingPlan && phase != .planReveal {
                    onboardingNavBar
                }

                // Main Step Content
                ZStack {
                    switch phase {
                    case .welcome:
                        OnboardingView(onUnlock: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                                phase = .account
                            }
                        })

                    case .account:
                        AccountStepView(
                            email: $profile.email,
                            password: $password,
                            confirmPassword: $confirmPassword,
                            isExistingUser: $isExistingUser,
                            isPasswordPhase: $isPasswordPhase,
                            isChecking: isCheckingUser,
                            errorMessage: errorMessage,
                            onContinueWithEmail: handleEmailCheck,
                            onSignInWithApple: handleAppleSignIn,
                            onContinueAsGuest: {
                                profile.email = ""
                                SupabaseService.shared.saveLocalProfile(profile)
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                    phase = .personal
                                }
                            },
                            onChangeEmail: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                    isPasswordPhase = false
                                    password = ""
                                    confirmPassword = ""
                                    errorMessage = nil
                                }
                            }
                        )
                        .padding(.horizontal, 24)

                    case .personal:
                        PersonalDetailsStepView(name: $profile.name)
                            .padding(.horizontal, 24)

                    case .screenTime:
                        ScreenTimeStepView(
                            hours: $profile.estimatedDailyScreenTimeHours,
                            primaryActivity: $profile.primaryActivity,
                            peakFatigueTime: $profile.peakFatigueTime,
                            actualHours: $profile.actualDailyScreenTimeHours
                        )
                        .padding(.horizontal, 24)

                    case .eyePower:
                        EyePowerStepView(
                            hasLenses: $profile.hasGlassesOrContacts,
                            leftPower: $profile.leftEyePower,
                            rightPower: $profile.rightEyePower
                        )
                        .padding(.horizontal, 24)

                    case .conditions:
                        ConditionsStepView(
                            selectedConditions: Binding(
                                get: { Set(profile.previousConditions) },
                                set: { profile.previousConditions = Array($0) }
                            )
                        )
                        .padding(.horizontal, 24)

                    case .generatingPlan:
                        generatingPlanView

                    case .planReveal:
                        if let blueprint = planBlueprint {
                            PersonalizedPlanRevealView(
                                blueprint: blueprint,
                                userName: profile.name,
                                onStart: handleFinalizeOnboarding
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Bottom Action Buttons (for post-unlock questionnaire steps)
                if shouldShowBottomBar {
                    bottomActionBar
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var shouldShowBottomBar: Bool {
        phase != .welcome && phase != .generatingPlan && phase != .planReveal
    }

    // MARK: - Navigation Bar
    private var onboardingNavBar: some View {
        HStack(spacing: 14) {
            Button {
                goBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(Typography.subheadline(weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .glassEffect(.clear, in: .circle)
                    )
            }
            .buttonStyle(.plain)

            // Step Progress Capsules
            HStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { idx in
                    Capsule()
                        .fill(idx <= currentStepIndex ? Palette.amber : Color.white.opacity(0.15))
                        .frame(height: 4)
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentStepIndex)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }

    private var currentStepIndex: Int {
        switch phase {
        case .account: return 0
        case .personal: return 1
        case .screenTime: return 2
        case .eyePower: return 3
        case .conditions: return 4
        default: return 0
        }
    }

    // MARK: - Bottom Action Bar
    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Button(action: handleNextStep) {
                HStack(spacing: 8) {
                    if isCheckingUser {
                        ProgressView()
                            .tint(.black)
                    }
                    Text(nextButtonTitle)
                        .font(Typography.headline(weight: .bold))
                        .foregroundStyle(Color.black)

                    Image(systemName: "arrow.right")
                        .font(Typography.subheadline(weight: .bold))
                        .foregroundStyle(Color.black)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 44, style: .continuous)
                        .fill(Palette.warmGradient)
                        .glassEffect(.clear, in: .capsule)
                        .shadow(color: Palette.ember.opacity(0.45), radius: 14, x: 0, y: 5)
                )
            }
            .buttonStyle(.plain)
            .disabled(isCheckingUser)
            .padding(.horizontal, 22)
            .padding(.bottom, 24)
        }
    }

    private var nextButtonTitle: String {
        switch phase {
        case .account:
            if !isPasswordPhase {
                return "Continue"
            } else {
                return isExistingUser ? "Sign In" : "Create Account"
            }
        case .conditions:
            return "Generate My Plan"
        default:
            return "Next"
        }
    }

    // MARK: - Generating Plan Transition View
    private var generatingPlanView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Palette.blobGlow.opacity(0.45), Palette.blobGlow.opacity(0)],
                            center: .center,
                            startRadius: 4,
                            endRadius: 130
                        )
                    )
                    .frame(width: 220, height: 220)

                Image("Luc")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .shadow(color: Palette.blobGlow.opacity(0.5), radius: 20, y: 8)
            }

            VStack(spacing: 8) {
                Text("Analyzing Your Profile...")
                    .font(Typography.title2(weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Synthesizing daily exercise stack and calibrating baseline strain metrics.")
                    .font(Typography.footnote())
                    .foregroundStyle(Color.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            }

            ProgressView()
                .tint(Palette.amber)
                .scaleEffect(1.2)
                .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            let blueprint = PersonalizationEngine.shared.generateBlueprint(from: profile)
            self.planBlueprint = blueprint

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    phase = .planReveal
                }
            }
        }
    }

    // MARK: - Back Navigation Logic
    private func goBack() {
        errorMessage = nil

        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            switch phase {
            case .account:
                if isPasswordPhase {
                    isPasswordPhase = false
                } else {
                    phase = .welcome
                }
            case .personal:
                phase = .account
            case .screenTime:
                phase = .personal
            case .eyePower:
                phase = .screenTime
            case .conditions:
                phase = .eyePower
            default:
                break
            }
        }
    }

    private func handleNextStep() {
        errorMessage = nil

        switch phase {
        case .account:
            if !isPasswordPhase {
                handleEmailCheck()
            } else {
                handlePasswordSubmit()
            }

        case .personal:
            if profile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errorMessage = "Please enter your name to continue."
                return
            }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                phase = .screenTime
            }

        case .screenTime:
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                phase = .eyePower
            }

        case .eyePower:
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                phase = .conditions
            }

        case .conditions:
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                phase = .generatingPlan
            }

        default:
            break
        }
    }

    // Phase 1: Email Existence Check via Supabase
    private func handleEmailCheck() {
        let cleanEmail = profile.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if cleanEmail.isEmpty {
            profile.email = ""
            SupabaseService.shared.saveLocalProfile(profile)
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                phase = .personal
            }
            return
        }

        let emailPattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        guard cleanEmail.range(of: emailPattern, options: [.regularExpression, .caseInsensitive]) != nil else {
            errorMessage = "Please enter a valid email address."
            return
        }

        isCheckingUser = true
        errorMessage = nil
        Task {
            let exists = await SupabaseService.shared.checkUserExists(email: cleanEmail)
            self.isCheckingUser = false
            self.isExistingUser = exists
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                self.isPasswordPhase = true
            }
        }
    }

    // Phase 2: Password Verification or Account Creation
    private func handlePasswordSubmit() {
        let cleanEmail = profile.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if isExistingUser {
            // Sign in existing user
            guard !password.isEmpty else {
                errorMessage = "Please enter your password to sign in."
                return
            }
            isCheckingUser = true
            errorMessage = nil
            Task {
                let verified = await SupabaseService.shared.verifyPassword(email: cleanEmail, password: password)
                if verified {
                    if let existingProfile = await SupabaseService.shared.fetchProfile(byEmail: cleanEmail) {
                        self.profile = existingProfile
                        SupabaseService.shared.saveLocalProfile(existingProfile)

                        // If user previously completed onboarding, restore plan directly and finish
                        if !existingProfile.name.isEmpty && !existingProfile.recommendedExerciseIds.isEmpty {
                            let bp = PersonalizationEngine.shared.generateBlueprint(from: existingProfile)
                            PersonalizationEngine.shared.applyBlueprint(bp, to: &self.profile)
                            self.isCheckingUser = false
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                onFinished()
                            }
                            return
                        }
                    }
                    self.isCheckingUser = false
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                        phase = .personal
                    }
                } else {
                    self.isCheckingUser = false
                    self.errorMessage = "Incorrect password. Please try again."
                }
            }
        } else {
            // Create brand new account
            guard password.count >= 6 else {
                errorMessage = "Password must be at least 6 characters."
                return
            }
            guard password == confirmPassword else {
                errorMessage = "Passwords do not match."
                return
            }

            isCheckingUser = true
            errorMessage = nil
            Task {
                let result = await SupabaseService.shared.createUser(
                    email: cleanEmail,
                    password: password,
                    name: profile.name.isEmpty ? nil : profile.name
                )
                self.isCheckingUser = false
                switch result {
                case .success(let createdProfile):
                    self.profile = createdProfile
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                        phase = .personal
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // Apple Sign In Handler
    private func handleAppleSignIn(_ auth: ASAuthorization) {
        if let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential {
            let email = (appleIDCredential.email ?? "\(appleIDCredential.user.prefix(12))@privaterelay.appleid.com").lowercased()
            let fullName = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")

            profile.email = email
            if !fullName.isEmpty {
                profile.name = fullName
            }

            isCheckingUser = true
            errorMessage = nil
            Task {
                let exists = await SupabaseService.shared.checkUserExists(email: email)
                if exists {
                    if let existing = await SupabaseService.shared.fetchProfile(byEmail: email) {
                        self.profile = existing
                        SupabaseService.shared.saveLocalProfile(existing)

                        if !existing.name.isEmpty && !existing.recommendedExerciseIds.isEmpty {
                            let bp = PersonalizationEngine.shared.generateBlueprint(from: existing)
                            PersonalizationEngine.shared.applyBlueprint(bp, to: &self.profile)
                            self.isCheckingUser = false
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                onFinished()
                            }
                            return
                        }
                    }
                } else {
                    let randomPass = "apple_\(UUID().uuidString.prefix(12))"
                    let result = await SupabaseService.shared.createUser(
                        email: email,
                        password: randomPass,
                        name: fullName.isEmpty ? nil : fullName
                    )
                    if case .success(let created) = result {
                        self.profile = created
                    }
                }
                self.isCheckingUser = false
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                    phase = .personal
                }
            }
        }
    }

    private func handleFinalizeOnboarding() {
        if let blueprint = planBlueprint {
            PersonalizationEngine.shared.applyBlueprint(blueprint, to: &profile)
        }

        profile.updatedAt = Date()
        SupabaseService.shared.saveLocalProfile(profile)

        // Upsert to Supabase with latest blueprint and credentials
        Task {
            _ = await SupabaseService.shared.upsertProfile(profile, password: password.isEmpty ? nil : password)
        }

        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            onFinished()
        }
    }
}
