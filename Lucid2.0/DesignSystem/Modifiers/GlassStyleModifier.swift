//
//  GlassStyleModifier.swift
//  Lucid2.0
//
//  Created by Antigravity on 21/09/26.
//

import SwiftUI

public struct GlassCardModifier: ViewModifier {
    public let cornerRadius: CGFloat
    public let topColor: Color
    public let bottomColor: Color
    public let strokeOpacity: Double

    public init(
        cornerRadius: CGFloat = 20,
        topColor: Color = Palette.cardTop,
        bottomColor: Color = Palette.cardBottom,
        strokeOpacity: Double = 0.16
    ) {
        self.cornerRadius = cornerRadius
        self.topColor = topColor
        self.bottomColor = bottomColor
        self.strokeOpacity = strokeOpacity
    }

    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [topColor.opacity(0.85), bottomColor.opacity(0.92)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(strokeOpacity), Color.white.opacity(strokeOpacity * 0.25)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

public struct GlassPressStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.965 : 1.0)
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

public extension View {
    func glassCard(
        cornerRadius: CGFloat = 20,
        topColor: Color = Palette.cardTop,
        bottomColor: Color = Palette.cardBottom,
        strokeOpacity: Double = 0.16
    ) -> some View {
        self.modifier(GlassCardModifier(cornerRadius: cornerRadius, topColor: topColor, bottomColor: bottomColor, strokeOpacity: strokeOpacity))
    }
}
