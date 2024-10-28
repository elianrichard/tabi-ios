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
    var inputBackgroundColor: Color = .uiWhite
    var inputCornerRadius: CGFloat = .infinity
    
    enum inputType: String{
        case text
        case price
        case phone
        
        var keyboard: UIKeyboardType {
            switch self {
            case .text:
                    .default
            case .price:
                    .numberPad
            case .phone:
                    .phonePad
            }
        }
    }
    
    var inputTypePicked: inputType = .text
    
    @Binding var text: String
    @Binding var price: Float
    var errorMessage: String?
    
    // Initializer for text input only
    init(label: String, placeholder: String, text: Binding<String>, errorMessage: String? = nil, inputBackgroundColor: Color = .uiWhite, inputCornerRadius: CGFloat = .infinity, isSecure: Bool = false) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self._price = .constant(0)  // Default to nil
        self.errorMessage = errorMessage
        self.inputTypePicked = .text
        self.inputBackgroundColor = inputBackgroundColor
        self.inputCornerRadius = inputCornerRadius
        self.isSecure = isSecure
    }
    
    // Initializer for price input only
    init(label: String, placeholder: String, price: Binding<Float>, errorMessage: String? = nil, inputBackgroundColor: Color = .uiWhite, inputCornerRadius: CGFloat = .infinity) {
        self.label = label
        self.placeholder = placeholder
        self._text = .constant("")  // Default to empty string
        self._price = price
        self.errorMessage = errorMessage
        self.inputTypePicked = .price
        self.inputBackgroundColor = inputBackgroundColor
        self.inputCornerRadius = inputCornerRadius
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8){
            Text(label)
                .font(.tabiBody)
            switch inputTypePicked {
            case .text:
                Input(placeholder: placeholder,
                      isSecure: isSecure,
                      text: $text, isError: errorMessage != nil, type: inputTypePicked.keyboard, backgroundColor: inputBackgroundColor, cornerRadius: inputCornerRadius)
            case .price:
                PriceInput(placeholder: placeholder, price: $price, type: inputTypePicked.keyboard, isError: errorMessage != nil, backgroundColor: inputBackgroundColor, cornerRadius: inputCornerRadius)
            case .phone:
                Input(placeholder: placeholder,
                      isSecure: isSecure,
                      text: $text, isError: errorMessage != nil, type: inputTypePicked.keyboard, backgroundColor: inputBackgroundColor, cornerRadius: inputCornerRadius)
            }
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

