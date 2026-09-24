//
//  SettingsView.swift
//  Lucid2.0
//
//  Created by Antigravity on 24/09/26.
//

import SwiftUI
import UserNotifications

// MARK: - Settings View

public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = true
    
    // Notification toggles
    @AppStorage("lucid_setting_daily_reminder") private var dailyReminderEnabled: Bool = true
    @AppStorage("lucid_setting_screen_breaks") private var screenBreaksEnabled: Bool = true
    @AppStorage("lucid_setting_streak_saver") private var streakSaverEnabled: Bool = true
    @AppStorage("lucid_setting_weekly_reports") private var weeklyReportsEnabled: Bool = true
    @AppStorage("lucid_setting_reminder_hour") private var reminderHour: Int = 10
    @AppStorage("lucid_setting_reminder_minute") private var reminderMinute: Int = 0
    
    // App Preferences
    @AppStorage("lucid_setting_haptics") private var hapticsEnabled: Bool = true
    @AppStorage("lucid_setting_sound") private var soundEnabled: Bool = true
    @AppStorage("lucid_setting_strict_mode") private var strictModeEnabled: Bool = false
    
    @State private var supabase = SupabaseService.shared
    @State private var areSystemNotificationsEnabled: Bool = false
    @State private var showLogoutDialog: Bool = false
    @State private var isSavingProfile: Bool = false
    @State private var showSavedToast: Bool = false
    
    // Editable Profile fields
    @State private var nameInput: String = ""
    @State private var leftEyeInput: Double = 0.0
    @State private var rightEyeInput: Double = 0.0
    @State private var primaryActivity: String = "General / Multitasking"
    @State private var peakFatigueTime: String = "Evening (after 7 PM)"
    
    public var onLogout: (() -> Void)? = nil

    public init(onLogout: (() -> Void)? = nil) {
        self.onLogout = onLogout
    }

    private let primaryActivities = [
        "Engineering / Coding",
        "Design & Creative",
        "Reading & Writing",
        "Gaming & Streaming",
        "Finance & Spreadsheets",
        "General / Multitasking"
    ]

    private let fatigueTimes = [
        "Morning (9 AM - 12 PM)",
        "Afternoon (1 PM - 4 PM)",
        "Late Afternoon (4 PM - 7 PM)",
        "Evening (after 7 PM)"
    ]

    public var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            // Ambient background glow
            RadialGradient(
                colors: [Color.white.opacity(0.04), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Custom Header Bar
                headerBar

                ScrollView {
                    VStack(spacing: 24) {
                        // Section 1: Account & Profile
                        accountSection

                        // Section 2: Notification Preferences
                        notificationsSection

                        // Section 3: Shielding & Screen Time Preferences
                        shieldingSection

                        // Section 4: App Preferences & Info
                        preferencesSection

                        // Section 5: Log Out
                        logoutSection

                        Spacer().frame(height: 60)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
                .scrollIndicators(.hidden)
            }

            // Save Toast Banner
            if showSavedToast {
                VStack {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(Typography.headline())
                        Text("Profile updated successfully")
                            .font(Typography.subheadline(weight: .medium, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background {
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .glassEffect(.clear, in: .capsule)
                            .overlay {
                                Capsule().strokeBorder(.white.opacity(0.14), lineWidth: 1)
                            }
                    }
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    
                    Spacer()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog(
            "Log Out",
            isPresented: $showLogoutDialog,
            titleVisibility: .visible
        ) {
            Button("Log Out", role: .destructive) {
                executeLogout()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to log out? Your vision records and training progress are saved to your account.")
        }
        .onAppear {
            loadInitialSettings()
        }
    }

    // MARK: - Header Bar
    private var headerBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(Typography.footnote(weight: .semibold))
                    Text("Back")
                        .font(Typography.subheadline(weight: .medium, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .glassEffect(.clear, in: .capsule)
                        .overlay {
                            Capsule().strokeBorder(.white.opacity(0.14), lineWidth: 1)
                        }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Settings")
                .font(Typography.headline(weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            Button {
                saveProfileChanges()
            } label: {
                if isSavingProfile {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(width: 14, height: 14)
                        .padding(.horizontal, 10)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(Typography.footnote(weight: .semibold))
                        Text("Save")
                            .font(Typography.subheadline(weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                    .background {
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .glassEffect(.clear, in: .capsule)
                            .overlay {
                                Capsule().strokeBorder(.white.opacity(0.14), lineWidth: 1)
                            }
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(isSavingProfile)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background(.black.opacity(0.75))
    }

    // MARK: - Section 1: Account
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Account & Vision Profile", icon: "person.crop.circle.fill")

            VStack(spacing: 14) {
                // Identity banner
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 48, height: 48)
                        Image(systemName: "person.fill")
                            .font(Typography.hero(size: 20, relativeTo: .title3))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(nameInput.isEmpty ? "Vision Explorer" : nameInput)
                            .font(Typography.headline(weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text(supabase.currentProfile?.email.isEmpty == false ? (supabase.currentProfile?.email ?? "Offline Account") : "Offline Account")
                            .font(Typography.caption(design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                    }

                    Spacer()

                    Text("Active")
                        .font(Typography.caption2(weight: .bold, design: .rounded))
                        .foregroundStyle(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background {
                            Capsule().fill(.green.opacity(0.15))
                        }
                }
                .padding(.bottom, 4)

                Divider().background(.white.opacity(0.08))

                // Name field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Display Name")
                        .font(Typography.caption(weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))

                    TextField("Enter your name", text: $nameInput)
                        .font(Typography.subheadline(design: .rounded))
                        .foregroundStyle(.white)
                        .padding(12)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.04))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12).strokeBorder(.white.opacity(0.08), lineWidth: 1)
                                }
                        }
                }

                // Eye Prescription Steppers
                HStack(spacing: 12) {
                    // Left Eye
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Left Eye (OS)")
                            .font(Typography.caption(weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))

                        HStack {
                            Text(String(format: "%.2f D", leftEyeInput))
                                .font(Typography.subheadline(weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)

                            Spacer()

                            Stepper("", value: $leftEyeInput, in: -15.0...10.0, step: 0.25)
                                .labelsHidden()
                        }
                        .padding(10)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.04))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12).strokeBorder(.white.opacity(0.08), lineWidth: 1)
                                }
                        }
                    }

                    // Right Eye
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Right Eye (OD)")
                            .font(Typography.caption(weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))

                        HStack {
                            Text(String(format: "%.2f D", rightEyeInput))
                                .font(Typography.subheadline(weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)

                            Spacer()

                            Stepper("", value: $rightEyeInput, in: -15.0...10.0, step: 0.25)
                                .labelsHidden()
                        }
                        .padding(10)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.04))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12).strokeBorder(.white.opacity(0.08), lineWidth: 1)
                                }
                        }
                    }
                }

                // Primary Activity Picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("Primary Screen Activity")
                        .font(Typography.caption(weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))

                    Picker("Primary Activity", selection: $primaryActivity) {
                        ForEach(primaryActivities, id: \.self) { act in
                            Text(act).tag(act)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.04))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12).strokeBorder(.white.opacity(0.08), lineWidth: 1)
                            }
                    }
                }

                // Peak Fatigue Time
                VStack(alignment: .leading, spacing: 6) {
                    Text("Peak Fatigue Window")
                        .font(Typography.caption(weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))

                    Picker("Peak Fatigue", selection: $peakFatigueTime) {
                        ForEach(fatigueTimes, id: \.self) { time in
                            Text(time).tag(time)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.04))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12).strokeBorder(.white.opacity(0.08), lineWidth: 1)
                            }
                    }
                }
            }
            .padding(18)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                    }
            }
        }
    }

    // MARK: - Section 2: Notifications
    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Notifications & Alerts", icon: "bell.badge.fill")

            VStack(spacing: 16) {
                // System notification status alert
                if !areSystemNotificationsEnabled {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(Typography.title3())

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Notifications Disabled")
                                .font(Typography.subheadline(weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)

                            Text("Enable iOS notifications to receive daily exercise alerts.")
                                .font(Typography.caption2(design: .rounded))
                                .foregroundStyle(.white.opacity(0.55))
                        }

                        Spacer()

                        Button("Enable") {
                            Task {
                                let granted = await NotificationSetupManager.shared.requestAuthorization()
                                await MainActor.run {
                                    areSystemNotificationsEnabled = granted
                                }
                            }
                        }
                        .font(Typography.caption(weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background {
                            Capsule()
                                .fill(.white.opacity(0.12))
                                .glassEffect(.clear, in: .capsule)
                                .overlay {
                                    Capsule().strokeBorder(.white.opacity(0.14), lineWidth: 1)
                                }
                        }
                    }
                    .padding(12)
                    .background {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.ultraThinMaterial)
                            .overlay {
                                RoundedRectangle(cornerRadius: 14).strokeBorder(.white.opacity(0.08), lineWidth: 1)
                            }
                    }
                }

                // Daily Reminder Toggle
                Toggle(isOn: $dailyReminderEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Training Reminder")
                            .font(Typography.subheadline(weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Scheduled prompt for your daily vision stack")
                            .font(Typography.caption2(design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }
                .tint(Palette.amber)

                if dailyReminderEnabled {
                    HStack {
                        Text("Reminder Time")
                            .font(Typography.subheadline(design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))

                        Spacer()

                        DatePicker(
                            "",
                            selection: reminderDateBinding,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .colorScheme(.dark)
                    }
                    .padding(.vertical, 2)
                }

                Divider().background(.white.opacity(0.08))

                // Screen break prompt
                Toggle(isOn: $screenBreaksEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("20-20-20 Screen Breaks")
                            .font(Typography.subheadline(weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Micro-nudges to blink and relax accommodation")
                            .font(Typography.caption2(design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }
                .tint(Palette.amber)

                Divider().background(.white.opacity(0.08))

                // Streak saver
                Toggle(isOn: $streakSaverEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Streak Saver Alert")
                            .font(Typography.subheadline(weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Evening alert at 8 PM if daily care is incomplete")
                            .font(Typography.caption2(design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }
                .tint(Palette.amber)

                Divider().background(.white.opacity(0.08))

                // Weekly report
                Toggle(isOn: $weeklyReportsEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Weekly Vision Insights")
                            .font(Typography.subheadline(weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Summary of screen time saved and score trends")
                            .font(Typography.caption2(design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }
                .tint(Palette.amber)
            }
            .padding(18)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                    }
            }
        }
    }

    // MARK: - Section 3: Shielding & Screen Time
    private var shieldingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Care & App Shielding", icon: "shield.lefthalf.filled")

            VStack(spacing: 16) {
                Toggle(isOn: $strictModeEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Strict Shielding Mode")
                            .font(Typography.subheadline(weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Requires 5s unblock hold on distracting applications")
                            .font(Typography.caption2(design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }
                .tint(Palette.amber)

                Divider().background(.white.opacity(0.08))

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Baseline Screen Goal")
                            .font(Typography.subheadline(weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Target maximum daily screen usage")
                            .font(Typography.caption2(design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    Spacer()
                    Text(String(format: "%.1f hrs", supabase.currentProfile?.estimatedDailyScreenTimeHours ?? 6.0))
                        .font(Typography.subheadline(weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .padding(18)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                    }
            }
        }
    }

    // MARK: - Section 4: Preferences & App Info
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Preferences & System", icon: "slider.horizontal.3")

            VStack(spacing: 14) {
                Toggle(isOn: $hapticsEnabled) {
                    Text("Haptic Feedback")
                        .font(Typography.subheadline(weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                }
                .tint(Palette.amber)

                Divider().background(.white.opacity(0.08))

                Toggle(isOn: $soundEnabled) {
                    Text("Sound Effects & Audio Cues")
                        .font(Typography.subheadline(weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                }
                .tint(Palette.amber)

                Divider().background(.white.opacity(0.08))

                HStack {
                    Text("Version")
                        .font(Typography.subheadline(weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                    Spacer()
                    Text("2.0.0 (Build 42)")
                        .font(Typography.caption(design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                }

                Divider().background(.white.opacity(0.08))

                HStack {
                    Text("Clinical Advisory")
                        .font(Typography.subheadline(weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                    Spacer()
                    Text("Vision Science 2026")
                        .font(Typography.caption(design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .padding(18)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                    }
            }
        }
    }

    // MARK: - Section 5: Log Out
    private var logoutSection: some View {
        VStack(spacing: 12) {
            Button {
                showLogoutDialog = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(Typography.callout(weight: .bold))
                        .foregroundStyle(.red)

                    Text("Log Out")
                        .font(Typography.headline(weight: .bold, design: .rounded))
                        .foregroundStyle(.red)

                    Spacer()

                    if let email = supabase.currentProfile?.email, !email.isEmpty {
                        Text(email)
                            .font(Typography.caption(design: .rounded))
                            .foregroundStyle(.white.opacity(0.35))
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.red.opacity(0.10))
                        .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(Color.red.opacity(0.28), lineWidth: 1.2)
                        }
                }
            }
            .buttonStyle(.plain)

            Text("Logging out will reset the active session. You can re-authenticate anytime.")
                .font(Typography.caption2(design: .rounded))
                .foregroundStyle(.white.opacity(0.3))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding(.top, 8)
    }

    // MARK: - Helpers
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(Typography.footnote(weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
            Text(title)
                .font(Typography.subheadline(weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
                .textCase(.uppercase)
                .kerning(0.8)
        }
    }

    private var reminderDateBinding: Binding<Date> {
        Binding<Date>(
            get: {
                var components = DateComponents()
                components.hour = reminderHour
                components.minute = reminderMinute
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                reminderHour = comps.hour ?? 10
                reminderMinute = comps.minute ?? 0
            }
        )
    }

    private func loadInitialSettings() {
        Task {
            let enabled = await NotificationSetupManager.shared.areNotificationsEnabled()
            await MainActor.run {
                areSystemNotificationsEnabled = enabled
            }
        }

        if let current = supabase.currentProfile {
            nameInput = current.name
            leftEyeInput = current.leftEyePower
            rightEyeInput = current.rightEyePower
            primaryActivity = current.primaryActivity
            peakFatigueTime = current.peakFatigueTime
        }
    }

    private func saveProfileChanges() {
        isSavingProfile = true
        var updated = supabase.currentProfile ?? UserProfile()
        updated.name = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.leftEyePower = leftEyeInput
        updated.rightEyePower = rightEyeInput
        updated.hasGlassesOrContacts = abs(leftEyeInput) > 0.1 || abs(rightEyeInput) > 0.1
        updated.primaryActivity = primaryActivity
        updated.peakFatigueTime = peakFatigueTime
        updated.updatedAt = Date()

        supabase.saveLocalProfile(updated)

        Task {
            _ = await supabase.upsertProfile(updated)
            await MainActor.run {
                isSavingProfile = false
                withAnimation {
                    showSavedToast = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        showSavedToast = false
                    }
                }
            }
        }
    }

    private func executeLogout() {
        if hapticsEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        
        // 1. Clear session in SupabaseService and UserDefaults
        supabase.logout()
        
        // 2. Set hasCompletedOnboarding to false so ContentView switches to Onboarding/Login
        hasCompletedOnboarding = false
        
        // 3. Inform parent ProfileView to dismiss
        onLogout?()
        
        // 4. Dismiss this settings sheet/view
        dismiss()
    }
}
