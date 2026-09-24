//
//  ProtectView.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import SwiftUI

public struct ProtectView: View {
    public init() {}

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "shield.fill")
                    .font(Typography.hero(size: 56, relativeTo: .largeTitle))
                    .foregroundStyle(Palette.warmGradient)
                    .padding(.bottom, 8)

                Text("Care & Protection")
                    .font(Typography.title2(weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Manage your scheduled blocking, screen time limits, and digital eye strain protocols.")
                    .font(Typography.subheadline())
                    .foregroundStyle(Color.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }
}

#Preview {
    ProtectView()
}
