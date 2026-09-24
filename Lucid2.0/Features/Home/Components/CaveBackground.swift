//
//  CaveBackground.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import SwiftUI

public struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    public init(seed: UInt64) { state = seed }

    public mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

public struct CaveBackground: View {
    public init() {}

    public var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            var rng = SeededRNG(seed: 2026)

            func rand() -> CGFloat {
                CGFloat(Double.random(in: 0...1, using: &rng))
            }

            // Turns a coarse list of normalized points into a craggy edge
            func edge(_ pts: [(CGFloat, CGFloat)]) -> [CGPoint] {
                var out: [CGPoint] = []
                for i in 0..<(pts.count - 1) {
                    let a = CGPoint(x: pts[i].0 * w, y: pts[i].1 * h)
                    let b = CGPoint(x: pts[i + 1].0 * w, y: pts[i + 1].1 * h)
                    for s in 0..<6 {
                        let t = CGFloat(s) / 6
                        out.append(CGPoint(x: a.x + (b.x - a.x) * t + (rand() - 0.5) * 9,
                                           y: a.y + (b.y - a.y) * t + (rand() - 0.5) * 9))
                    }
                }
                if let last = pts.last {
                    out.append(CGPoint(x: last.0 * w, y: last.1 * h))
                }
                return out
            }

            // 1. Night sky — navy, matching Luc's shadow side
            ctx.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(
                    Gradient(colors: [Color(red: 0.10, green: 0.13, blue: 0.24),
                                      Color(red: 0.02, green: 0.03, blue: 0.06),
                                      Color.black]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: 0, y: h)
                )
            )

            // 2. Stars
            for _ in 0..<120 {
                let x = w * (0.2 + 0.6 * rand())
                let y = h * 0.5 * rand()
                let r = 0.4 + rand() * rand()
                let alpha = Double(0.25 + 0.6 * rand())
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: r * 2, height: r * 2)),
                    with: .color(Color.white.opacity(alpha))
                )
            }

            // 3. Rock walls
            let leftEdge = edge([(0.37, 0.00), (0.34, 0.07), (0.29, 0.15), (0.245, 0.24),
                                 (0.21, 0.31), (0.19, 0.39), (0.17, 0.48), (0.135, 0.53)])
            let rightEdge = edge([(0.73, 0.00), (0.70, 0.06), (0.65, 0.15), (0.63, 0.20),
                                  (0.675, 0.27), (0.80, 0.36), (0.87, 0.46), (0.93, 0.53)])

            var leftWall = Path()
            leftWall.move(to: .zero)
            for pt in leftEdge { leftWall.addLine(to: pt) }
            leftWall.addLine(to: CGPoint(x: 0, y: h * 0.62))
            leftWall.closeSubpath()

            var rightWall = Path()
            rightWall.move(to: CGPoint(x: w, y: 0))
            for pt in rightEdge { rightWall.addLine(to: pt) }
            rightWall.addLine(to: CGPoint(x: w, y: h * 0.62))
            rightWall.closeSubpath()

            let wallShading = GraphicsContext.Shading.linearGradient(
                Gradient(colors: [Color(red: 0.26, green: 0.30, blue: 0.42),
                                  Color(red: 0.04, green: 0.05, blue: 0.08)]),
                startPoint: .zero,
                endPoint: CGPoint(x: 0, y: h * 0.55)
            )

            for wall in [leftWall, rightWall] {
                ctx.fill(wall, with: wallShading)
                // Rock grain
                ctx.drawLayer { layer in
                    layer.clip(to: wall)
                    for _ in 0..<700 {
                        let x = rand() * w
                        let y = rand() * h * 0.6
                        let len = 4 + rand() * 12
                        let ang = Double((rand() - 0.5) * 1.2 + 0.3)
                        var line = Path()
                        line.move(to: CGPoint(x: x, y: y))
                        line.addLine(to: CGPoint(x: x + CGFloat(cos(ang)) * len,
                                                 y: y + CGFloat(sin(ang)) * len))
                        let isLight = rand() > 0.45
                        let col: Color = isLight
                            ? Color.white.opacity(Double(0.04 + rand() * 0.10))
                            : Color.black.opacity(0.35)
                        layer.stroke(line, with: .color(col), lineWidth: 0.8 + rand())
                    }
                }
            }

            // 4. Pedestal slab
            let slabTop = h * 0.51
            var slab = Path()
            slab.move(to: CGPoint(x: w * 0.12, y: h * 0.62))
            slab.addQuadCurve(to: CGPoint(x: w * 0.24, y: slabTop + 6),
                              control: CGPoint(x: w * 0.14, y: slabTop + 10))
            slab.addLine(to: CGPoint(x: w * 0.30, y: slabTop))
            slab.addLine(to: CGPoint(x: w * 0.72, y: slabTop - 2))
            slab.addQuadCurve(to: CGPoint(x: w * 0.88, y: slabTop + 14),
                              control: CGPoint(x: w * 0.84, y: slabTop - 2))
            slab.addLine(to: CGPoint(x: w * 0.98, y: h * 0.66))
            slab.addLine(to: CGPoint(x: w, y: h))
            slab.addLine(to: CGPoint(x: 0, y: h))
            slab.closeSubpath()

            ctx.fill(
                slab,
                with: .linearGradient(
                    Gradient(colors: [Color(red: 0.17, green: 0.20, blue: 0.29),
                                      Color(red: 0.04, green: 0.05, blue: 0.08)]),
                    startPoint: CGPoint(x: 0, y: slabTop),
                    endPoint: CGPoint(x: 0, y: h * 0.82)
                )
            )
            ctx.drawLayer { layer in
                layer.clip(to: slab)
                for _ in 0..<500 {
                    let x = rand() * w
                    let y = slabTop + rand() * (h - slabTop) * 0.6
                    let len = 4 + rand() * 12
                    var line = Path()
                    line.move(to: CGPoint(x: x, y: y))
                    line.addLine(to: CGPoint(x: x + len, y: y + (rand() - 0.5) * 4))
                    let isLight = rand() > 0.5
                    let col: Color = isLight
                        ? Color.white.opacity(Double(0.03 + rand() * 0.07))
                        : Color.black.opacity(0.3)
                    layer.stroke(line, with: .color(col), lineWidth: 0.8 + rand())
                }
            }

            // 5. Base the blob floats above — warm rim so Luc's glow feels like it lands
            let base = CGRect(x: w / 2 - 52, y: slabTop - 6, width: 104, height: 24)
            ctx.fill(Path(roundedRect: base, cornerRadius: 9), with: .color(Color(white: 0.02)))
            ctx.stroke(Path(roundedRect: base, cornerRadius: 9),
                       with: .color(Palette.ember.opacity(0.22)), lineWidth: 1)

            // 6. Fade to black at the bottom
            ctx.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(
                    Gradient(stops: [
                        Gradient.Stop(color: Color.black.opacity(0), location: 0.55),
                        Gradient.Stop(color: Color.black.opacity(0.93), location: 0.93)
                    ]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: 0, y: h)
                )
            )
        }
    }
}
