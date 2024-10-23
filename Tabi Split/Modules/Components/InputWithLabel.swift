//
//  InputWithLabel.swift
//  Tabi
//
//  Created by ahmad naufal alfakhar on 03/10/24.
//

import SwiftUI

struct InputWithLabel: View {
    var label: String = "Label"
    var placeholder: String = "Placeholder"
    var isSecure: Bool = false
    
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8){
            Text(label)
                .font(.tabiBody)
            Input(placeholder: placeholder,
                  isSecure: isSecure,
                  text: $text)
        }
    }
}

#Preview {
    InputWithLabel(text: .constant(""))
}
