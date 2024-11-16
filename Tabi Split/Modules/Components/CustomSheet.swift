//
//  CustomSheet.swift
//  Tabi Split
//
//  Created by Elian Richard on 16/11/24.
//

import SwiftUI

struct CustomSheet<Content: View>: View {
    var xToggleBinding: (Binding<Bool>)? = nil
    var content: Content
    
    init(xToggleBinding: (Binding<Bool>)? = nil, @ViewBuilder content: () -> Content) {
        self.xToggleBinding = xToggleBinding
        self.content = content()
    }
    
    var body: some View {
        VStack (spacing: 0) {
            if let xToggleBinding {
                SheetXButton(toggle: xToggleBinding)
            }
            content
        }
        .padding()
    }
}
