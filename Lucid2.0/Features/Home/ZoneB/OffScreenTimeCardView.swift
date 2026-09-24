//
//  OffScreenTimeCardView.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import SwiftUI

public struct OffScreenTimeCardView: View {
    public init() {}

    public var body: some View {
        ScreenAwayTime()
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        OffScreenTimeCardView()
            .padding()
    }
}
