//
//  LoadingView.swift
//  Tabi Split
//
//  Created by Elian Richard on 12/12/24.
//

import SwiftUI
import Lottie

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color(.white).opacity(0.8)
            LottieView(animation: .named("LoadingComponent"))
                .looping()
        }
        .ignoresSafeArea()
    }
}

#Preview {
    LoadingView()
}
