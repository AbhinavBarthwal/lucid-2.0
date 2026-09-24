//
//  Palette.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import SwiftUI

public enum Palette {
    public static let amber      = Color(red: 1.00, green: 0.72, blue: 0.20)   // #FFB833
    public static let ember      = Color(red: 0.99, green: 0.44, blue: 0.02)   // #FD7005
    public static let honey      = Color(red: 1.00, green: 0.87, blue: 0.55)   // pale gradient tip
    public static let cardTop    = Color(red: 0.08, green: 0.13, blue: 0.25)
    public static let cardBottom = Color(red: 0.03, green: 0.05, blue: 0.11)
    public static let inkTop     = Color(red: 0.05, green: 0.07, blue: 0.13)
    public static let inkBottom  = Color(red: 0.02, green: 0.03, blue: 0.06)
    public static let blobGlow   = Color(red: 1.00, green: 0.50, blue: 0.10)
//    public static let amber      = Color(red: 1.00, green: 0.30, blue: 0.55)   // vibrant pink #FF4D8D
//    public static let ember      = Color(red: 0.88, green: 0.14, blue: 0.44)   // deep raspberry pink #E02470
//    public static let honey      = Color(red: 1.00, green: 0.78, blue: 0.86)   // pastel blush pink #FFC7DC
//    public static let cardTop    = Color(red: 0.20, green: 0.08, blue: 0.15)   // dark rose plum #331426
//    public static let cardBottom = Color(red: 0.10, green: 0.04, blue: 0.08)   // deep midnight rose #1A0A14
//    public static let inkTop     = Color(red: 0.12, green: 0.05, blue: 0.09)   // deep ink rose #1F0D17
//    public static let inkBottom  = Color(red: 0.06, green: 0.02, blue: 0.04)   // darkest rose #0F050A
//    public static let blobGlow   = Color(red: 1.00, green: 0.15, blue: 0.55)   // neon pink glow #FF268C

    public static var warmGradient: LinearGradient {
        LinearGradient(colors: [honey, ember], startPoint: .top, endPoint: .bottom)
    }
}
