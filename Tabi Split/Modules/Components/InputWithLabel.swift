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
    var isDisabled: Bool
    var inputTypePicked: InputTypeEnum
    
    @Binding var text: String
    @Binding var price: Float
    var errorMessage: String?
    
    @FocusState.Binding var focusedField: FocusField?
    var focusCase: FocusField

    // Initializer for text input only
    init(label: String, placeholder: String, text: Binding<String>, errorMessage: String? = nil, isSecure: Bool = false, isDisabled: Bool = false, inputTypePicked: InputTypeEnum = .text, focusedField: FocusState<FocusField?>.Binding, focusCase: FocusField) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self._price = .constant(0)  // Default to nil
        self.errorMessage = errorMessage
        self.inputTypePicked = inputTypePicked
        self.isSecure = isSecure
        self.isDisabled = isDisabled
        self._focusedField = focusedField
        self.focusCase = focusCase
    }
    
    // Initializer for price input only
    init(label: String, placeholder: String, price: Binding<Float>, errorMessage: String? = nil, isDisabled: Bool = false, focusedField: FocusState<FocusField?>.Binding, focusCase: FocusField) {
        self.label = label
        self.placeholder = placeholder
        self._text = .constant("")  // Default to empty string
        self._price = price
        self.errorMessage = errorMessage
        self.inputTypePicked = .price
        self.isDisabled = isDisabled
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
                      text: $text,
                      isError: errorMessage != nil,
                      isDisabled: isDisabled,
                      type: inputTypePicked,
                      focusedField: $focusedField,
                      focusCase: focusCase)
            case .price:
                PriceInput(placeholder: placeholder,
                           price: $price,
                           type: inputTypePicked.keyboard,
                           isError: errorMessage != nil)
            }
            if let message = errorMessage {
                Text(message)
                    .font(.tabiBody)
                    .foregroundStyle(.buttonRed)
            }
        }
    }
}
