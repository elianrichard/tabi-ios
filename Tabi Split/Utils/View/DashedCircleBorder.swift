//
//  DashedCircleBorder.swift
//  Tabi Split
//
//  Created by Elian Richard on 17/11/24.
//

import SwiftUI

// This is used in the View+Ext addBackgroundModifier function
struct DashedCircleBorder: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay {
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 5]))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .foregroundColor(.bgGreyOverlay)
            }
    }
}
