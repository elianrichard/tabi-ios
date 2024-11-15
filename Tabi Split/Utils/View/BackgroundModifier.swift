//
//  BackgroundModifier.swift
//  Tabi Split
//
//  Created by Elian Richard on 30/10/24.
//

import SwiftUI

// This is used in the View+Ext addBackgroundModifier function
struct BackgroundModifier: ViewModifier {
    var color: Color
    var onBackgroundTap: (() -> Void)?
    
    init(color: Color, onBackgroundTap: (() -> Void)? = nil) {
        self.color = color
        self.onBackgroundTap = onBackgroundTap
    }

    func body(content: Content) -> some View {
        ZStack {
            Color(color)
                .ignoresSafeArea()
                .onTapGesture {
                    onBackgroundTap?()
                }
            content
        }
    }
}
