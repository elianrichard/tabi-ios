//
//  Input.swift
//  Tabi
//
//  Created by ahmad naufal alfakhar on 03/10/24.
//

import SwiftUI

struct Input: View {
    var placeholder: String = ""
    var isSecure: Bool = false
    @Binding var text: String
    var isError: Bool = false
    var type: UIKeyboardType = .default
    
    @State var isShowPassword = false
    
    var body: some View {
        HStack {
            if isSecure {
                HStack {
                    if !isShowPassword {
                        SecureField("", text: $text,
                                    prompt: Text(placeholder).foregroundStyle(.textGrey))
                        .frame(height: 20)
                    } else {
                        TextField("", text: $text,
                                  prompt: Text(placeholder).foregroundStyle(.textGrey))
                        .frame(height: 20)
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
                .keyboardType(type)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(.uiWhite)
        .clipShape(RoundedRectangle(cornerRadius: .infinity))
        .foregroundStyle(.black)
        .font(.tabiBody)
        .overlay {
            RoundedRectangle(cornerRadius: .infinity)
                .fill(.clear)
                .stroke(isError ? .buttonRed : .bgGreyOverlay, lineWidth: 0.5)
        }
    }
}

#Preview {
    Input(text: .constant(""))
}
