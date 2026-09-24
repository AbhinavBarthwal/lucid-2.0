//
//  OnboardingStepsViews.swift
//  Lucid2.0
//
//  Created by Antigravity on 21/09/26.
//

import SwiftUI
import AuthenticationServices

// MARK: - Step 1: Account Step (Two-Phase Auth + Apple Sign-In)
public struct AccountStepView: View {
    @Binding public var email: String
    @Binding public var password: String
    @Binding public var confirmPassword: String
    @Binding public var isExistingUser: Bool
    @Binding public var isPasswordPhase: Bool

    public var isChecking: Bool
    public var errorMessage: String?
    public var onContinueWithEmail: () -> Void
    public var onSignInWithApple: (ASAuthorization) -> Void
    public var onContinueAsGuest: () -> Void
    public var onChangeEmail: () -> Void

    public init(
        email: Binding<String>,
        password: Binding<String>,
        confirmPassword: Binding<String>,
        isExistingUser: Binding<Bool>,
        isPasswordPhase: Binding<Bool>,
        isChecking: Bool,
        errorMessage: String?,
        onContinueWithEmail: @escaping () -> Void,
        onSignInWithApple: @escaping (ASAuthorization) -> Void,
        onContinueAsGuest: @escaping () -> Void,
        onChangeEmail: @escaping () -> Void
    ) {
        self._email = email
        self._password = password
        self._confirmPassword = confirmPassword
        self._isExistingUser = isExistingUser
        self._isPasswordPhase = isPasswordPhase
        self.isChecking = isChecking
        self.errorMessage = errorMessage
        self.onContinueWithEmail = onContinueWithEmail
        self.onSignInWithApple = onSignInWithApple
        self.onContinueAsGuest = onContinueAsGuest
        self.onChangeEmail = onChangeEmail
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            if !isPasswordPhase {
                // PHASE 1: EMAIL & APPLE SIGN-IN
                VStack(alignment: .leading, spacing: 6) {
                    Text("Get Started")
                        .font(Typography.title(weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Save your personalized plan and synchronize across devices.")
                        .font(Typography.subheadline())
                        .foregroundStyle(Color.white.opacity(0.65))
                        .lineLimit(nil)
                }

                // Apple Sign-In Button
                SignInWithAppleButton(
                    .continue,
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        switch result {
                        case .success(let auth):
                            onSignInWithApple(auth)
                        case .failure(let err):
                            print("Apple Sign In error: \(err)")
                        }
                    }
                )
                .signInWithAppleButtonStyle(.white)
                .frame(height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 44, style: .continuous))
                .shadow(color: Color.black.opacity(0.4), radius: 10, y: 4)

                // Divider
                HStack(spacing: 12) {
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 1)
                    Text("or with email")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.white.opacity(0.4))
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 1)
                }
                .padding(.vertical, 4)

                // Email Input Field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Email Address")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Palette.amber)

                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                            .font(.subheadline)
                            .foregroundStyle(Color.white.opacity(0.4))

                        TextField("name@example.com", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .foregroundStyle(.white)

                        if isChecking {
                            ProgressView()
                                .tint(Palette.amber)
                                .scaleEffect(0.85)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 52)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                    )
                }

            } else {
                // PHASE 2: PASSWORD INPUT (LOGIN VS SIGNUP)
                VStack(alignment: .leading, spacing: 6) {
                    Text(isExistingUser ? "Welcome Back!" : "Create Your Password")
                        .font(Typography.title(weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(isExistingUser
                         ? "Enter your password to restore your saved profile."
                         : "Set a secure password for your new Lucid account.")
                        .font(Typography.subheadline())
                        .foregroundStyle(Color.white.opacity(0.65))
                }

                // Email Badge with "Change" button
                HStack(spacing: 10) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.headline)
                        .foregroundStyle(Palette.amber)

                    Text(email)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Spacer()

                    Button("Change", action: onChangeEmail)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Palette.amber)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Palette.amber.opacity(0.25), lineWidth: 1)
                )

                // Password Fields
                VStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Palette.amber)

                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .font(.subheadline)
                                .foregroundStyle(Color.white.opacity(0.4))

                            SecureField("Enter your password", text: $password)
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 52)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                        )
                    }

                    if !isExistingUser {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Confirm Password")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Palette.amber)

                            HStack(spacing: 12) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.white.opacity(0.4))

                                SecureField("Repeat your password", text: $confirmPassword)
                                    .foregroundStyle(.white)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                            )
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }

            // Error Message Banner
            if let errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(Color.red)
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Color.red.opacity(0.95))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Spacer()

            // Continue as Guest Option
            Button(action: onContinueAsGuest) {
                HStack(spacing: 6) {
                    Text("Continue as Guest / Skip for now")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Color.white.opacity(0.5))
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(Color.white.opacity(0.35))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 16)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: isPasswordPhase)
    }
}

// MARK: - Step 2: Personal Details
public struct PersonalDetailsStepView: View {
    @Binding public var name: String

    public init(name: Binding<String>) {
        self._name = name
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text("What should we call you?")
                    .font(Typography.title(weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Luc will address you personally during your exercises and daily check-ins.")
                    .font(Typography.subheadline())
                    .foregroundStyle(Color.white.opacity(0.65))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Your Name")
                    .font(Typography.footnote(weight: .semibold))
                    .foregroundStyle(Palette.amber)

                HStack(spacing: 12) {
                    Image(systemName: "person.fill")
                        .font(Typography.title3())
                        .foregroundStyle(Palette.warmGradient)

                    TextField("e.g. Abhinav", text: $name)
                        .font(Typography.title3(weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 18)
                .frame(height: 60)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                )
            }

            Spacer()
        }
        .padding(.top, 16)
    }
}

// MARK: - Step 3: Screen Time & Discrepancy Step
public struct ScreenTimeStepView: View {
    @Binding public var hours: Double
    @Binding public var primaryActivity: String
    @Binding public var peakFatigueTime: String
    public let actualHours: Double?

    private let activities = [
        ("Coding & Reading", "laptopcomputer"),
        ("Video & Gaming", "play.tv.fill"),
        ("Office & Writing", "doc.text.fill"),
        ("Social & Mobile", "iphone")
    ]

    private let fatigueTimes = [
        "Morning (9–12)",
        "Midday (1–4)",
        "Late Day (5–8)",
        "Night (8+)"
    ]

    public init(
        hours: Binding<Double>,
        primaryActivity: Binding<String>,
        peakFatigueTime: Binding<String>,
        actualHours: Double? = nil
    ) {
        self._hours = hours
        self._primaryActivity = primaryActivity
        self._peakFatigueTime = peakFatigueTime
        self.actualHours = actualHours
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Daily Screen Time")
                        .font(Typography.title(weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Estimate how much time you spend looking at screens every day.")
                        .font(Typography.subheadline())
                        .foregroundStyle(Color.white.opacity(0.65))
                }

                // Big Numeric Display with Stepper
                VStack(spacing: 12) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(String(format: "%.1f", hours))
                            .font(Typography.hero(size: 64, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())

                        Text("hrs / day")
                            .font(Typography.title3(weight: .medium, design: .rounded))
                            .foregroundStyle(Palette.amber)
                    }
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: hours)

                    // Interactive Slider
                    Slider(value: $hours, in: 1.0...16.0, step: 0.5)
                        .tint(Palette.amber)
                        .padding(.horizontal, 10)

                    HStack {
                        Text("1h")
                        Spacer()
                        Text("8h")
                        Spacer()
                        Text("16h+")
                    }
                    .font(Typography.caption2(weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .padding(.horizontal, 12)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .cardBackground(top: Palette.cardTop, bottom: Palette.cardBottom, corner: 24)

                // Discrepancy Pill / Alert
                if let actual = actualHours {
                    let delta = actual - hours
                    let diffString = String(format: "%.1f", abs(delta))
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: delta > 0 ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                            .font(Typography.title3())
                            .foregroundStyle(delta > 0 ? Palette.amber : Color.green)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(delta > 0 ? "Screen Time Discrepancy Detected" : "Healthy Self-Awareness")
                                .font(Typography.headline())
                                .foregroundStyle(.white)

                            Text(delta > 0
                                 ? "Device Activity averages ~\(String(format: "%.1f", actual)) hrs/day (\(diffString) hrs higher than your estimate). Luc will account for this extra strain."
                                 : "Your actual screen activity matches your perception closely. Great awareness!")
                                .font(Typography.footnote())
                                .foregroundStyle(Color.white.opacity(0.75))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Palette.amber.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(Palette.amber.opacity(0.3), lineWidth: 1)
                            )
                    )
                }

                // Primary Activity Selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("Primary Screen Focus")
                        .font(Typography.footnote(weight: .semibold))
                        .foregroundStyle(Palette.amber)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(activities, id: \.0) { act in
                            let isSelected = primaryActivity == act.0
                            Button {
                                primaryActivity = act.0
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: act.1)
                                        .font(Typography.subheadline())
                                        .foregroundStyle(isSelected ? Palette.amber : Color.white.opacity(0.5))

                                    Text(act.0)
                                        .font(Typography.footnote(weight: .medium))
                                        .foregroundStyle(isSelected ? .white : Color.white.opacity(0.7))
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 12)
                                .frame(height: 46)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(isSelected ? Palette.amber.opacity(0.15) : Color.white.opacity(0.05))
                                        .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(isSelected ? Palette.amber : Color.white.opacity(0.1), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Peak Fatigue Time
                VStack(alignment: .leading, spacing: 10) {
                    Text("When do your eyes feel most tired?")
                        .font(Typography.footnote(weight: .semibold))
                        .foregroundStyle(Palette.amber)

                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 10) {
                            ForEach(fatigueTimes, id: \.self) { time in
                                let isSelected = peakFatigueTime == time
                                Button {
                                    peakFatigueTime = time
                                } label: {
                                    Text(time)
                                        .font(Typography.caption(weight: .semibold, design: .rounded))
                                        .foregroundStyle(isSelected ? Color.black : Color.white.opacity(0.85))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .frame(minWidth: 105, minHeight: 44)
                                        .background(
                                            Capsule()
                                                .fill(isSelected ? Palette.amber : Color.white.opacity(0.06))
                                                .glassEffect(.clear, in: .capsule)
                                        )
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(isSelected ? Palette.amber : Color.white.opacity(0.12), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Step 4: Eye Power Step
public struct EyePowerStepView: View {
    @Binding public var hasLenses: Bool
    @Binding public var leftPower: Double
    @Binding public var rightPower: Double

    public init(
        hasLenses: Binding<Bool>,
        leftPower: Binding<Double>,
        rightPower: Binding<Double>
    ) {
        self._hasLenses = hasLenses
        self._leftPower = leftPower
        self._rightPower = rightPower
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Do you wear glasses or contacts?")
                    .font(Typography.title(weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Knowing your refractive state helps Luc optimize focus and accommodation exercises.")
                    .font(Typography.subheadline())
                    .foregroundStyle(Color.white.opacity(0.65))
            }

            // Yes / No Selection
            HStack(spacing: 12) {
                choiceButton(title: "No, none", icon: "eye.fill", isSelected: !hasLenses) {
                    hasLenses = false
                    leftPower = 0.0
                    rightPower = 0.0
                }

                choiceButton(title: "Yes, I wear lenses", icon: "eyeglasses", isSelected: hasLenses) {
                    hasLenses = true
                    if leftPower == 0.0 && rightPower == 0.0 {
                        leftPower = -1.50
                        rightPower = -1.50
                    }
                }
            }

            // Diopter Adjustment if Yes
            if hasLenses {
                VStack(spacing: 18) {
                    diopterPicker(label: "Left Eye (OS)", value: $leftPower)
                    diopterPicker(label: "Right Eye (OD)", value: $rightPower)
                }
                .padding(20)
                .cardBackground(top: Palette.cardTop, bottom: Palette.cardBottom, corner: 24)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Spacer()
        }
        .padding(.top, 16)
    }

    private func choiceButton(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(isSelected ? Palette.amber : Color.white.opacity(0.5))

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? .white : Color.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? Palette.amber.opacity(0.14) : Color.white.opacity(0.06))
                    .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? Palette.amber : Color.white.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func diopterPicker(label: String, value: Binding<Double>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(Typography.subheadline(weight: .bold))
                    .foregroundStyle(.white)

                Text(formattedDiopter(value.wrappedValue))
                    .font(Typography.title3(weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.amber)
            }

            Spacer()

            HStack(spacing: 12) {
                Button {
                    value.wrappedValue = max(-12.0, value.wrappedValue - 0.25)
                } label: {
                    Image(systemName: "minus")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.08))
                                .glassEffect(.clear, in: .circle)
                        )
                }

                Button {
                    value.wrappedValue = min(8.0, value.wrappedValue + 0.25)
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.08))
                                .glassEffect(.clear, in: .circle)
                        )
                }
            }
        }
    }

    private func formattedDiopter(_ val: Double) -> String {
        if abs(val) < 0.05 {
            return "0.00 D (Plano)"
        }
        return String(format: "%+.2f D", val)
    }
}

// MARK: - Step 5: Conditions Step with Hold-to-Inspect Layman Info
public struct ConditionsStepView: View {
    @Binding public var selectedConditions: Set<String>
    @State private var inspectingSymptom: SymptomLaymanInfo? = nil

    private let conditionItems: [(name: String, icon: String)] = [
        ("Digital Eye Strain", "display"),
        ("Dry Eyes", "drop.fill"),
        ("Blurry Vision", "eye.trianglebadge.exclamationmark"),
        ("Eye Fatigue", "moon.fill"),
        ("Headaches / Neck Pain", "figure.walk"),
        ("Light Sensitivity", "sun.max.fill"),
        ("Astigmatism", "circle.dotted"),
        ("Presbyopia", "textformat.size"),
        ("Convergence Issues", "arrow.left.and.right")
    ]

    public init(selectedConditions: Binding<Set<String>>) {
        self._selectedConditions = selectedConditions
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Symptoms & History")
                        .font(Typography.title(weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Select any symptoms you experience regularly. Luc will tailor exercises specifically for relief.")
                        .font(Typography.subheadline())
                        .foregroundStyle(Color.white.opacity(0.65))
                }

                // Hold-to-Inspect Layman Prompt Banner
                HStack(spacing: 8) {
                    Image(systemName: "hand.tap.fill")
                        .font(Typography.caption(weight: .bold))
                        .foregroundStyle(Palette.amber)

                    Text("Tap to select · Press & hold any card to see why it happens")
                        .font(Typography.caption(weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.85))

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Palette.amber.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Palette.amber.opacity(0.28), lineWidth: 1)
                        )
                )

                // Grid of Symptoms
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(conditionItems, id: \.name) { item in
                        let isSelected = selectedConditions.contains(item.name)
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if isSelected {
                                    selectedConditions.remove(item.name)
                                } else {
                                    selectedConditions.insert(item.name)
                                }
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: item.icon)
                                        .font(.headline)
                                        .foregroundStyle(isSelected ? Palette.amber : Color.white.opacity(0.6))
                                    Spacer()
                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.footnote)
                                            .foregroundStyle(Palette.amber)
                                    }
                                }

                                Text(item.name)
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(isSelected ? .white : Color.white.opacity(0.85))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, minHeight: 74, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(isSelected ? Palette.amber.opacity(0.14) : Color.white.opacity(0.05))
                                    .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(isSelected ? Palette.amber : Color.white.opacity(0.12), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.38)
                                .onEnded { _ in
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                    if let info = SymptomLaymanInfo.catalog[item.name] {
                                        self.inspectingSymptom = info
                                    }
                                }
                        )
                    }
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .sheet(item: $inspectingSymptom) { info in
            SymptomLaymanDetailSheet(info: info) {
                inspectingSymptom = nil
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
            .presentationBackground(Color(red: 0.06, green: 0.08, blue: 0.14))
        }
    }
}
