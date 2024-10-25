//
//  DropDownInput.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 24/10/24.
//

import Foundation
import SwiftUI

struct InputWithLabel: View {
    var label: String
    var placeholder: String
    var isSecure: Bool = false
    var type: UIKeyboardType = .default
    var inputBackgroundColor: Color = .uiWhite
    var inputCornerRadius: CGFloat = .infinity
    
    @Binding var text: String
    var errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8){
            Text(label)
                .font(.tabiBody)
            Input(placeholder: placeholder,
                  isSecure: isSecure,
                  text: $text, isError: errorMessage != nil, type: type, backgroundColor: inputBackgroundColor, cornerRadius: inputCornerRadius)
            if let message = errorMessage {
                Text(message)
                    .font(.tabiBody)
                    .foregroundStyle(.buttonRed)
            }
        }
    }
}

#Preview {
    InputWithLabel(label: "Label", placeholder: "Placeholder", text: .constant(""))
}

