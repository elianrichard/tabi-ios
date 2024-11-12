//
//  BackgroundModifier.swift
//  Tabi Split
//
//  Created by Elian Richard on 30/10/24.
//

import SwiftUI

struct BackgroundModifier: ViewModifier {
    var color: Color

    func body(content: Content) -> some View {
        ZStack {
            Color(color)
                .ignoresSafeArea()
            content
        }
    }
}
