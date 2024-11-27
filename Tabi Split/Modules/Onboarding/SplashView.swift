//
//  SplashView.swift
//  Tabi Split
//
//  Created by Elian Richard on 18/11/24.
//

import SwiftUI

struct SplashView: View {
    @State private var isShowSplashScreen = true
    @State private var isRenderSplashScreen = true
    
    var body: some View {
        if isRenderSplashScreen {
            Color(.bgWhite)
                .overlay {
                    Image(.appLogo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                        withAnimation {
                            isShowSplashScreen = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                                isRenderSplashScreen = false
                            })
                        }
                    })
                }
                .allowsHitTesting(false)
                .opacity(isShowSplashScreen ? 1 : 0)
        } else {
            EmptyView()
        }
    }
}
