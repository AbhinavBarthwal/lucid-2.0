//
//  SetUpAppBlocking.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import SwiftUI

public struct SetUpAppBlocking: View {
    public var viewModel: AppBlockingViewModel?

    public init(viewModel: AppBlockingViewModel? = nil) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "person.badge.shield.checkmark.fill")
                    .font(Typography.headline())
                    .foregroundStyle(Palette.warmGradient)

                Text("Complete Your Setup")
                    .font(Typography.headline())
                    .foregroundStyle(Palette.amber)

                Spacer()
            }

            HStack(alignment: .center, spacing: 14) {
                // Stacked app icon preview
                ZStack {
                    Image("SnapchatLogo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .padding(.trailing, 22)
                        .padding(.bottom, 22)

                    Image("YoutubeLogo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Image("InstagramLogo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .padding([.top, .leading], 22)
                }
                .frame(width: 72, height: 72)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Set your Apps to be blocked")
                        .font(Typography.headline())
                        .foregroundStyle(.white)

                    Text("Access to these apps will be limited to protect you from digital eye strain")
                        .font(Typography.subheadline())
                        .foregroundStyle(Color.white.opacity(0.65))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Button {
                    viewModel?.openNewBlock()
                } label: {
                    Text("Set up")
                        .font(Typography.subheadline(weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 34)
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
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .cardBackground(top: Palette.inkTop, bottom: Palette.inkBottom, corner: 32)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        SetUpAppBlocking()
            .padding()
    }
}
