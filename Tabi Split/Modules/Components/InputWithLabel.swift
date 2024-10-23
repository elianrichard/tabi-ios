//
//  InputWithLabel.swift
//  Tabi
//
//  Created by ahmad naufal alfakhar on 03/10/24.
//

import SwiftUI

struct InputWithLabel: View {
    var label: String
    var placeholder: String
    var isSecure: Bool = false
    var type: UIKeyboardType = .default
    
    @Binding var text: String
    var errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8){
            Text(label)
                .font(.tabiBody)
            Input(placeholder: placeholder,
                  isSecure: isSecure,
                  text: $text, isError: errorMessage != nil, type: type)
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
