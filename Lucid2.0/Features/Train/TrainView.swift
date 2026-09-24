//
//  TrainView.swift
//  Lucid2.0
//

import SwiftUI

private struct TrainScrollOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

public struct TrainView: View {
    @State private var scrollY: CGFloat = 0
    @State private var baseline: CGFloat?
    @State private var showProfile = false

    public init() {}

    public var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 125)

                    ExerciseListView()
                }
                .background(alignment: .top) {
                    CaveBackground().frame(height: 600)
                }
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(key: TrainScrollOffsetKey.self,
                                               value: geo.frame(in: .global).minY)
                    }
                )
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .top)
            .onPreferenceChange(TrainScrollOffsetKey.self) { y in
                if baseline == nil { baseline = y }
                let delta = min(max((baseline ?? y) - y, 0), 120)
                if delta != scrollY { scrollY = delta }
            }

            // Header fade gradient overlay
            LinearGradient(
                stops: [
                    .init(color: .black, location: 0),
                    .init(color: Color.black.opacity(0.94), location: 0.55),
                    .init(color: Color.black.opacity(0), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 165)
            .opacity(Double(min(scrollY / 100, 1)))
            .allowsHitTesting(false)
            .ignoresSafeArea(edges: .top)

            // Top Header Bar
            TrainHeaderBar(onProfileTapped: {
                showProfile = true
            })
        }
        .fullScreenCover(isPresented: $showProfile) {
            ProfileView()
        }
    }
}

#Preview {
    TrainView()
}
