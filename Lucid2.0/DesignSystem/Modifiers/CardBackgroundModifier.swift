//
//  CardBackgroundModifier.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import SwiftUI

public struct CardBackgroundModifier: ViewModifier {
    public let top: Color
    public let bottom: Color
    public let corner: CGFloat

    public init(top: Color, bottom: Color, corner: CGFloat = 32) {
        self.top = top
        self.bottom = bottom
        self.corner = corner
    }

    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(LinearGradient(colors: [top, bottom],
                                         startPoint: .topLeading,
                                         endPoint: .bottomTrailing))
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [Color.white.opacity(0.14), Color.white.opacity(0.03)],
                                       startPoint: .top, endPoint: .bottom),
                        lineWidth: 1
                    )
            )
    }
}

public extension View {
    func cardBackground(top: Color, bottom: Color, corner: CGFloat = 32) -> some View {
        self.modifier(CardBackgroundModifier(top: top, bottom: bottom, corner: corner))
    }
}
