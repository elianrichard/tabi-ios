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
    var inputTypePicked: InputTypeEnum = .text
    
    @Binding var text: String
    @Binding var price: Float
    var errorMessage: String?
    
    @FocusState.Binding var focusedField: FocusField?
    var focusCase: FocusField

    // Initializer for text input only
    init(label: String, placeholder: String, text: Binding<String>, errorMessage: String? = nil, inputBackgroundColor: Color = .bgWhite, inputCornerRadius: CGFloat = .radiusMedium, isSecure: Bool = false, inputTypePicked: InputTypeEnum = .text, focusedField: FocusState<FocusField?>.Binding, focusCase: FocusField) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self._price = .constant(0)  // Default to nil
        self.errorMessage = errorMessage
        self.inputTypePicked = inputTypePicked
        self.inputBackgroundColor = inputBackgroundColor
        self.inputCornerRadius = inputCornerRadius
        self.isSecure = isSecure
        self._focusedField = focusedField
        self.focusCase = focusCase
    }
    
    // Initializer for price input only
    init(label: String, placeholder: String, price: Binding<Float>, errorMessage: String? = nil, inputBackgroundColor: Color = .bgWhite, inputCornerRadius: CGFloat = .radiusMedium, focusedField: FocusState<FocusField?>.Binding, focusCase: FocusField) {
        self.label = label
        self.placeholder = placeholder
        self._text = .constant("")  // Default to empty string
        self._price = price
        self.errorMessage = errorMessage
        self.inputTypePicked = .price
        self.inputBackgroundColor = inputBackgroundColor
        self.inputCornerRadius = inputCornerRadius
        self._focusedField = focusedField
        self.focusCase = focusCase
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8){
            Text(label)
                .font(.tabiBody)
            switch inputTypePicked {
            case .text, .phone:
                Input(placeholder: placeholder,
                      isSecure: isSecure,
                      text: $text, isError: errorMessage != nil, backgroundColor: inputBackgroundColor, cornerRadius: inputCornerRadius, type: inputTypePicked, focusedField: $focusedField, focusCase: focusCase)
            case .price:
                PriceInput(placeholder: placeholder, price: $price, type: inputTypePicked.keyboard, isError: errorMessage != nil, backgroundColor: inputBackgroundColor, cornerRadius: inputCornerRadius)
            }
            if let message = errorMessage {
                Text(message)
                    .font(.tabiBody)
                    .foregroundStyle(.buttonRed)
            }
        }
    }
}
