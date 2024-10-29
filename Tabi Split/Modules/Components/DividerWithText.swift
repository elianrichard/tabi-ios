//
//  DividerWithText.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 15/10/24.
//

import Foundation
import SwiftUI

struct DividerWithText: View {
    @State var text: String = "Or"
    var body: some View {
        HStack {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.uiGray)
            
            Text(text)
                .font(.tabiBody)
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.uiGray)
        }
    }
}
