//
//  ConnectorShape.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import SwiftUI

public struct ConnectorShape: Shape {
    public init() {}

    public func path(in rect: CGRect) -> Path {
        var p = Path()
        let r: CGFloat = 8
        let lineY = rect.minY + 7

        // Horizontal bar with rounded down-turns at both ends
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: lineY + r))
        p.addQuadCurve(to: CGPoint(x: rect.minX + r, y: lineY),
                       control: CGPoint(x: rect.minX, y: lineY))
        p.addLine(to: CGPoint(x: rect.maxX - r, y: lineY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: lineY + r),
                       control: CGPoint(x: rect.maxX, y: lineY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))

        // Center stem
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return p
    }
}
