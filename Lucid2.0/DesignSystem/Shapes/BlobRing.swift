//
//  BlobRing.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import SwiftUI

public struct BlobRing: Shape {
    public init() {}

    public func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        let x = rect.minX, y = rect.minY
        var p = Path()
        p.move(to: CGPoint(x: x + 0.50 * w, y: y))
        p.addCurve(to: CGPoint(x: x + w, y: y + 0.48 * h),
                   control1: CGPoint(x: x + 0.80 * w, y: y),
                   control2: CGPoint(x: x + w, y: y + 0.22 * h))
        p.addCurve(to: CGPoint(x: x + 0.55 * w, y: y + h),
                   control1: CGPoint(x: x + w, y: y + 0.80 * h),
                   control2: CGPoint(x: x + 0.82 * w, y: y + h))
        p.addCurve(to: CGPoint(x: x, y: y + 0.54 * h),
                   control1: CGPoint(x: x + 0.24 * w, y: y + h),
                   control2: CGPoint(x: x, y: y + 0.82 * h))
        p.addCurve(to: CGPoint(x: x + 0.50 * w, y: y),
                   control1: CGPoint(x: x, y: y + 0.24 * h),
                   control2: CGPoint(x: x + 0.22 * w, y: y))
        p.closeSubpath()
        return p
    }
}
