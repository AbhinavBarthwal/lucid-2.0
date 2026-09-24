//
//  NotificationSetupCard.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import SwiftUI
import UserNotifications

public struct NotificationSetupCard: View {
    public let onEnable: () -> Void
    public let onDismiss: () -> Void
    @ScaledMetric(relativeTo: .title) private var bellSize: CGFloat = 40

    public init(onEnable: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.onEnable = onEnable
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "person.fill.checkmark")
                    .font(Typography.headline())
                    .foregroundStyle(Palette.warmGradient)
                Text("Complete Your Setup")
                    .font(Typography.callout(weight: .semibold))
                    .foregroundStyle(Palette.amber)
                Spacer()
                Menu {
                    Button("Dismiss", role: .destructive, action: onDismiss)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(Typography.headline(weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 24)
                }
            }

            HStack(spacing: 14) {
                Image(systemName: "bell.badge.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Palette.warmGradient, Color.white)
                    .font(Typography.hero(size: 36, relativeTo: .title))
                    .frame(width: 48)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Enable Notifications")
                        .font(Typography.headline())
                        .foregroundStyle(.white)
                    Text("Be alerted before your blocking rules start")
                        .font(Typography.subheadline())
                        .foregroundStyle(Color.white.opacity(0.68))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Button(action: onEnable) {
                    Text("Enable")
                        .font(Typography.callout(weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 17)
                        .frame(minHeight: 32)
                        .background(
                            Capsule().fill(
                                LinearGradient(
                                    colors: [Color(red: 0.48, green: 0.29, blue: 0.07),
                                             Color(red: 0.24, green: 0.14, blue: 0.04)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                            .glassEffect(.clear, in: .capsule)
                        )
                        .overlay(Capsule().strokeBorder(Palette.amber.opacity(0.35), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .cardBackground(top: Palette.cardTop, bottom: Palette.cardBottom)
    }
}
