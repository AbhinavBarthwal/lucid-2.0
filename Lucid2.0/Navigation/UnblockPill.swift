//
//  UnblockPill.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import SwiftUI
import Combine

public struct UnblockPill: View {
    private static let defaultDuration: Int = 15 * 60 // 15 minutes
    private static let usedTodayKey = "unblock_pill_last_used_date"
    private static let userDefaults = UserDefaults(suiteName: "group.com.lucid2.appgroup") ?? .standard

    public var viewModel: AppBlockingViewModel?

    @State private var unblocked: Bool = false
    @State private var remaining: Int = UnblockPill.defaultDuration
    @State private var showHardModeAlert: Bool = false
    @State private var showUsedTodayAlert: Bool = false

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    public init(viewModel: AppBlockingViewModel? = nil) {
        self.viewModel = viewModel
    }

    /// Returns true if the 15-min unblock has already been used today.
    private var alreadyUsedToday: Bool {
        guard let lastUsed = UnblockPill.userDefaults.object(forKey: UnblockPill.usedTodayKey) as? Date else {
            return false
        }
        return Calendar.current.isDateInToday(lastUsed)
    }

    private var timeString: String {
        String(format: "%02d:%02d", remaining / 60, remaining % 60)
    }

    public var body: some View {
        Button {
            toggleUnblock()
        } label: {
            HStack(spacing: 10) {
                if unblocked {
                    AppIconBadge(color: Color(red: 0.10, green: 0.42, blue: 0.52), symbol: "lock.open.fill")
                    HStack(spacing: 8) {
                        Text("Unblocked")
                            .foregroundStyle(.white)
                        Text(timeString)
                            .monospacedDigit()
                            .foregroundStyle(Color.white.opacity(0.55))
                            .contentTransition(.numericText(countsDown: true))
                    }
                } else if alreadyUsedToday {
                    HStack(spacing: -4) {
                        AppIconBadge(color: Color(red: 0.35, green: 0.35, blue: 0.35), symbol: "lock.fill")
                        AppIconBadge(color: Color(red: 0.35, green: 0.35, blue: 0.35), symbol: "lock.fill")
                        AppIconBadge(color: Color(red: 0.35, green: 0.35, blue: 0.35), symbol: "lock.fill")
                    }
                    HStack(spacing: 6) {
                        Text("Used Today")
                        Image(systemName: "checkmark.circle.fill")
                            .font(Typography.subheadline(weight: .bold))
                    }
                    .foregroundStyle(.white.opacity(0.55))
                } else {
                    HStack(spacing: -4) {
                        AppIconBadge(color: Color(red: 0.10, green: 0.42, blue: 0.52), symbol: "lock.fill")
                        AppIconBadge(color: Color(red: 0.30, green: 0.24, blue: 0.62), symbol: "lock.fill")
                        AppIconBadge(color: Color(red: 0.90, green: 0.58, blue: 0.10), symbol: "lock.fill")
                    }
                    HStack(spacing: 6) {
                        Text("Unblock Apps")
                        Image(systemName: "chevron.right")
                            .font(Typography.subheadline(weight: .bold))
                    }
                    .foregroundStyle(.white)
                }
            }
            .font(Typography.headline())
            .padding(.horizontal, 16)
            .frame(minHeight: 43)
            .glassEffect(.clear, in: .capsule)
            .backgroundStyle(Color.black.opacity(0.1))
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.4), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: unblocked)
        .alert("Hard Mode Active", isPresented: $showHardModeAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This session is locked in Hard Mode to protect your focus. Mid-session unblocking is disabled.")
        }
        .alert("Already Used Today", isPresented: $showUsedTodayAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The 15-minute unblock can only be used once per day. It resets at midnight.")
        }
        .onReceive(ticker) { _ in
            guard unblocked else { return }
            if remaining > 0 {
                withAnimation { remaining -= 1 }
            } else {
                endUnblock()
            }
        }
    }

    private func toggleUnblock() {
        if unblocked {
            // User manually re-locks
            endUnblock()
        } else {
            // Check if active block has Hard Mode
            if let block = viewModel?.primaryBlock, viewModel?.isBlockActiveNow(block) == true, block.hardMode {
                showHardModeAlert = true
                return
            }

            // Enforce once-per-day limit
            if alreadyUsedToday {
                showUsedTodayAlert = true
                return
            }

            // Record usage date before starting the unblock
            UnblockPill.userDefaults.set(Date(), forKey: UnblockPill.usedTodayKey)

            // Start 15 min unblock
            remaining = UnblockPill.defaultDuration
            unblocked = true
            ScreenTimeService.shared.clearShield()
        }
    }

    private func endUnblock() {
        unblocked = false
        remaining = UnblockPill.defaultDuration
        // If an active block exists, re-apply shield
        if let block = viewModel?.primaryBlock,
           viewModel?.isBlockActiveNow(block) == true,
           let selection = viewModel?.primaryBlockSelection {
            ScreenTimeService.shared.applyShield(for: selection)
        }
    }
}

public struct AppIconBadge: View {
    public let color: Color
    public let symbol: String

    public init(color: Color, symbol: String) {
        self.color = color
        self.symbol = symbol
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: 7, style: .continuous)
            .fill(LinearGradient(colors: [color, color.opacity(0.7)],
                                 startPoint: .top, endPoint: .bottom))
            .frame(width: 22, height: 22)
            .overlay(
                Image(systemName: symbol)
                    .font(Typography.caption2(weight: .bold))
                    .foregroundStyle(.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.45), lineWidth: 1.5)
            )
    }
}
