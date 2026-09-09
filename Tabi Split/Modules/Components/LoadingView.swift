//
//  LoadingView.swift
//  Tabi Split
//
//  Created by Elian Richard on 12/12/24.
//

import SwiftUI
import Lottie

struct LoadingView: View {
    @State private var loadingViewModel = LoadingViewModel.shared

    var body: some View {
        ZStack {
            Color(.white).opacity(0.8)
            LottieView(animation: .named(loadingViewModel.animationName))
                .looping()
                // Rebuild the LottieView when the animation changes mid-loading.
                .id(loadingViewModel.animationName)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    LoadingView()
}
