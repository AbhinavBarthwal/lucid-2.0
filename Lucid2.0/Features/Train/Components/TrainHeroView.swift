//
//  TrainHeroView.swift
//  Lucid2.0
//

import SwiftUI

public struct TrainHeroView: View {
    @State private var floating = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Palette.amber.opacity(0.15), Palette.amber.opacity(0)],
                            center: .center,
                            startRadius: 2,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(floating ? 1.05 : 0.95)
                
                // Icon
                Image(systemName: "eye.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(Palette.warmGradient)
                    .shadow(color: Palette.ember.opacity(0.3), radius: 15, y: 8)
                    .offset(y: floating ? -4 : 4)
            }
            .frame(width: 140, height: 140)
            .padding(.top, 100)
            .animation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true), value: floating)
            .onAppear { floating = true }
        }
        .frame(maxWidth: .infinity)
        .background {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.07, blue: 0.13), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        TrainHeroView()
    }
}
