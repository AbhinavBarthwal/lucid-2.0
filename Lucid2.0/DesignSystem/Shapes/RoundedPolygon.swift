//
//  RoundedPolygon.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import SwiftUI

public struct RoundedPolygon: Shape {
    public var sides: Int
    public var cornerRadius: CGFloat

    public init(sides: Int = 6, cornerRadius: CGFloat = 8) {
        self.sides = sides
        self.cornerRadius = cornerRadius
    }

    public func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        let pts: [CGPoint] = (0..<sides).map { i in
            let a = (Double(i) / Double(sides)) * 2 * Double.pi - Double.pi / 2
            return CGPoint(x: c.x + r * CGFloat(cos(a)), y: c.y + r * CGFloat(sin(a)))
        }
        var p = Path()
        let start = CGPoint(x: (pts[sides - 1].x + pts[0].x) / 2,
                            y: (pts[sides - 1].y + pts[0].y) / 2)
        p.move(to: start)
        for i in 0..<sides {
            p.addArc(tangent1End: pts[i],
                     tangent2End: pts[(i + 1) % sides],
                     radius: cornerRadius)
        }
        p.closeSubpath()
        return p
    }
}
