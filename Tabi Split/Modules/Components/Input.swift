//
//  Input.swift
//  Tabi
//
//  Created by ahmad naufal alfakhar on 03/10/24.
//

import SwiftUI

enum FocusField {
    case field1, field2, field3, field4
}

enum InputTypeEnum: String{
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

struct Input: View {
    var placeholder: String = ""
    var isSecure: Bool = false
    @Binding var text: String
    var isError: Bool = false
    var isDisabled: Bool = false
    var backgroundColor: Color = .bgWhite
    var cornerRadius: CGFloat = .radiusMedium
    
    @State var isShowPassword = false
    
    var type: InputTypeEnum = .text
    var phoneCode: String = "62"
    
    @FocusState.Binding var focusedField: FocusField?
    var focusCase: FocusField
    
    var body: some View {
        HStack(spacing: .spacingRegular) {
            if type == .phone {
                Text("+" + phoneCode)
                    .font(.tabiBody)
                    .foregroundColor(.buttonGrey)
                Divider()
                    .frame(height: 19)
                    .background(.buttonGrey)
            }
            if isSecure {
                HStack {
                    if !isShowPassword {
                        SecureField("", text: $text,
                                    prompt: Text(placeholder).foregroundStyle(.textGrey))
                        .frame(height: 20)
                        .focused($focusedField, equals: focusCase)
                        .disabled(isDisabled)
                    } else {
                        TextField("", text: $text,
                                  prompt: Text(placeholder).foregroundStyle(.textGrey))
                        .frame(height: 20)
                        .focused($focusedField, equals: focusCase)
                        .disabled(isDisabled)
                    }
                    
                    Button {
                        isShowPassword.toggle()
                    } label: {
                        Icon(isShowPassword ? .eyeIcon : .hiddenEyeIcon)
                            .foregroundStyle(.textGrey)
                    }
                }
            } else {
                TextField("", text: $text,
                          prompt: Text(placeholder).foregroundStyle(.textGrey))
                .frame(height: 20)
                .keyboardType(type.keyboard)
                .focused($focusedField, equals: focusCase)
                .disabled(isDisabled)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(isDisabled ? .uiGray : backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .foregroundStyle(isDisabled ? .textGrey : .black)
        .font(.tabiBody)
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.clear)
                .stroke(isError ? .buttonRed : .bgGreyOverlay, lineWidth: 0.5)
                .padding(0.5)
        }
    }
}
