//
//  CareBlockingCard.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import SwiftUI
import FamilyControls
import ManagedSettings

public struct CareBlockingCard: View {
    public var viewModel: AppBlockingViewModel?
    public var onOpenCareTab: (() -> Void)? = nil

    public init(viewModel: AppBlockingViewModel? = nil, onOpenCareTab: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onOpenCareTab = onOpenCareTab
    }

    private var activeBlock: ScheduledBlock? {
        viewModel?.blocks.first
    }

    private var isActive: Bool {
        guard let block = activeBlock else { return false }
        return viewModel?.isBlockActiveNow(block) ?? false
    }

    private var statusText: String {
        guard let block = activeBlock else { return "No Active Schedule" }
        if isActive {
            return "\(block.name) is Active Now"
        } else {
            return "\(block.name) starts at \(block.fromTimeFormatted)"
        }
    }

    private var timeFrameText: String {
        if let block = activeBlock {
            return "\(block.fromTimeFormatted) – \(block.toTimeFormatted)"
        }
        return "6:00 PM – 6:45 PM"
    }

    private var daysText: String {
        if let block = activeBlock {
            return block.daysSummary
        }
        return "Weekdays"
    }

    public var body: some View {
        // Dependency hook to ensure dynamic re-render on any block/selection updates
        let _ = viewModel?.lastUpdated

        VStack(alignment: .leading, spacing: 0) {
            // 1. Header: Care Title + Chevron (Navigates to Care Tab)
            HStack {
                Button {
                    onOpenCareTab?()
                } label: {
                    HStack(spacing: 6) {
                        Text("Care")
                            .font(Typography.headline())
                            .foregroundStyle(Color.white.opacity(0.5))

                        Image(systemName: "chevron.right")
                            .font(Typography.subheadline(weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.5))
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                // Edit / Manage Block button that opens sheet
                Button {
                    if let block = activeBlock {
                        viewModel?.openEditBlock(block)
                    } else {
                        viewModel?.openNewBlock()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.3")
                            .font(Typography.footnote(weight: .medium))
                        Text("Manage")
                            .font(Typography.footnote(weight: .medium))
                    }
                    .foregroundStyle(Palette.amber)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Palette.amber.opacity(0.12))
                            .glassEffect(.clear, in: .capsule)
                    )
                    .overlay(Capsule().strokeBorder(Palette.amber.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            // 2. Active / Upcoming Status Row
            HStack(spacing: 12) {
                if isActive {
                    Image(systemName: "shield.checkered")
                        .font(Typography.title2())
                        .foregroundStyle(Color(red: 52/255, green: 211/255, blue: 153/255))
                } else {
                    Image(systemName: "shield.fill")
                        .font(Typography.title2())
                        .foregroundStyle(Palette.warmGradient)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(statusText)
                        .font(Typography.headline())
                        .foregroundStyle(.white)

                    // Categories and protected apps summary
                    categoryAndAppsSummaryView
                }

                Spacer()

                if isActive {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color(red: 52/255, green: 211/255, blue: 153/255))
                            .frame(width: 7, height: 7)
                        Text("Active")
                            .font(Typography.caption(weight: .bold))
                            .foregroundStyle(Color(red: 52/255, green: 211/255, blue: 153/255))
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color(red: 52/255, green: 211/255, blue: 153/255).opacity(0.14)))
                }
            }
            .padding(.top, 14)

            // 3. Hairline Divider
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
                .padding(.top, 16)

            // 4. Dynamic Protected Apps / Categories Row (Reflects actual selection!)
            protectedIconsRow
                .padding(.top, 16)

            // 5. Beneath the Care section, at the bottom: Time and Day part
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
                .padding(.top, 16)

            HStack(spacing: 16) {
                // Time part
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(Typography.footnote(weight: .semibold))
                        .foregroundStyle(Color(red: 52/255, green: 211/255, blue: 153/255))

                    Text(timeFrameText)
                        .font(Typography.footnote(weight: .semibold))
                        .foregroundStyle(Color(red: 52/255, green: 211/255, blue: 153/255))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(Color(red: 52/255, green: 211/255, blue: 153/255).opacity(0.10))
                )

                // Day part
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(Typography.footnote(weight: .medium))
                        .foregroundStyle(Palette.amber)

                    Text(daysText)
                        .font(Typography.footnote(weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.8))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(Palette.amber.opacity(0.10))
                )

                Spacer()
            }
            .padding(.top, 14)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground(top: Palette.inkTop, bottom: Palette.inkBottom, corner: 32)
    }

    // MARK: - Category & Apps Summary

    @ViewBuilder
    private var categoryAndAppsSummaryView: some View {
        let categoryItems = viewModel?.primaryCategoryItems ?? []
        let appItems = viewModel?.primaryAppItems ?? []

        if !categoryItems.isEmpty {
            // Show real Category name chips
            HStack(spacing: 6) {
                ForEach(Array(categoryItems.prefix(2))) { item in
                    HStack(spacing: 4) {
                        if let token = item.token {
                            Label(token)
                                .labelStyle(.iconOnly)
                                .font(Typography.caption2())
                            Label(token)
                                .labelStyle(.titleOnly)
                                .font(Typography.caption(weight: .semibold))
                                .foregroundStyle(.white.opacity(0.9))
                        } else {
                            Image(systemName: item.iconSymbol)
                                .font(Typography.caption2(weight: .semibold))
                                .foregroundStyle(Palette.amber)
                            Text(item.name)
                                .font(Typography.caption(weight: .semibold))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.white.opacity(0.10)))
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8))
                }

                if categoryItems.count > 2 {
                    Text("+\(categoryItems.count - 2)")
                        .font(Typography.caption2(weight: .bold))
                        .foregroundStyle(Palette.amber)
                }

                if !appItems.isEmpty {
                    Text("• \(appItems.count) Apps")
                        .font(Typography.caption(weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.6))
                }
            }
        } else if !appItems.isEmpty {
            HStack(spacing: 4) {
                Image(systemName: "app.badge.checkmark.fill")
                    .font(Typography.caption2())
                    .foregroundStyle(Palette.amber)
                Text("\(appItems.count) Apps Protected")
                    .font(Typography.footnote(weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.75))
            }
        } else {
            HStack(spacing: 4) {
                Image(systemName: "square.grid.2x2.fill")
                    .font(Typography.caption2())
                    .foregroundStyle(Palette.amber)
                Text("Social & Entertainment")
                    .font(Typography.footnote(weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.6))
            }
        }
    }

    // MARK: - Dynamic Protected Icons Row

    @ViewBuilder
    private var protectedIconsRow: some View {
        let categoryItems = viewModel?.primaryCategoryItems ?? []
        let appItems = viewModel?.primaryAppItems ?? []

        if !appItems.isEmpty {
            // Render actual selected application tokens or apps
            HStack(spacing: 12) {
                ForEach(Array(appItems.prefix(3))) { app in
                    if let token = app.token {
                        Label(token)
                            .labelStyle(.iconOnly)
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                            )
                    } else {
                        AppIconTile(imageName: "", fallbackSymbol: "app.fill", tint: Palette.amber)
                    }
                }

                if appItems.count > 3 {
                    moreCountTile(count: appItems.count - 3)
                }

                Spacer()
            }
        } else if !categoryItems.isEmpty {
            // Render selected categories as rich glass icon tiles!
            HStack(spacing: 12) {
                ForEach(Array(categoryItems.prefix(3))) { item in
                    ZStack {
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Palette.amber.opacity(0.25), Palette.cardTop],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )

                        if let token = item.token {
                            Label(token)
                                .labelStyle(.iconOnly)
                                .font(Typography.title3())
                                .foregroundStyle(Palette.warmGradient)
                        } else {
                            Image(systemName: item.iconSymbol)
                                .font(Typography.title3(weight: .bold))
                                .foregroundStyle(Palette.warmGradient)
                        }
                    }
                    .frame(width: 48, height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .strokeBorder(Palette.amber.opacity(0.3), lineWidth: 1)
                    )
                }

                if categoryItems.count > 3 {
                    moreCountTile(count: categoryItems.count - 3)
                }

                Spacer()
            }
        } else {
            // Fallback / Initial sample tiles for empty state
            HStack(spacing: 12) {
                AppIconTile(imageName: "SnapchatLogo", fallbackSymbol: "bubble.left.fill", tint: Color.yellow)
                AppIconTile(imageName: "InstagramLogo", fallbackSymbol: "camera.fill", tint: Color.pink)
                AppIconTile(imageName: "YoutubeLogo", fallbackSymbol: "play.rectangle.fill", tint: Color.red)

                moreCountTile(count: 2)

                Spacer()
            }
        }
    }

    private func moreCountTile(count: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.14, green: 0.20, blue: 0.34).opacity(0.8),
                                 Color(red: 0.08, green: 0.12, blue: 0.22).opacity(0.6)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
            Text("+\(count)")
                .font(Typography.subheadline(weight: .bold, design: .rounded))
                .foregroundStyle(Palette.amber)
        }
        .frame(width: 48, height: 48)
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .strokeBorder(Palette.amber.opacity(0.25), lineWidth: 1)
        )
    }
}

private struct AppIconTile: View {
    let imageName: String
    let fallbackSymbol: String
    let tint: Color

    var body: some View {
        Group {
            if UIImage(named: imageName) != nil {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.8), tint.opacity(0.5)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: fallbackSymbol)
                            .font(Typography.title3(weight: .bold))
                            .foregroundStyle(.white)
                    )
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        CareBlockingCard()
            .padding()
    }
}
