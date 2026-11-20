//
//  PulsingActionButton.swift
//  Lucid2.0
//
//  Shared "breathing" glass capsule CTA — originally the 20-20-20 intro's
//  "Begin Exercise" button, extracted so other entry points (the Protect
//  tab's "Start 20-20-20" card) can reuse the exact same animation.
//

import SwiftUI

public struct PulsingActionButton: View {
    public let title: String
    public let systemImage: String
    public let tint: Color

    public let action: () -> Void

    public init(
        title: String,
        systemImage: String,
        tint: Color = .yellow,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(.white)
                .symbolEffect(.pulse, options: .repeating)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.tint(tint.opacity(0.55)).interactive(), in: Capsule())
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        PulsingActionButton(title: "Begin Exercise", systemImage: "leaf.fill", action: {})
            .padding(.horizontal, 36)
    }
}
