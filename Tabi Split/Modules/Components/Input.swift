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
    var backgroundColor: Color = .bgWhite
    var cornerRadius: CGFloat = .radiusMedium
    
    @State var isShowPassword = false
    
    enum inputType: String{
        case text
        case phone
        
        var keyboard: UIKeyboardType {
            switch self {
            case .text:
                    .default
            case .phone:
                    .phonePad
            }
        }
    }
    var type: inputType = .text
    var phoneCode: String = "62"
    
    var body: some View {
        HStack(spacing: .spacingRegular){
            if type == .phone{
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
                .keyboardType(type.keyboard)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .foregroundStyle(.black)
        .font(.tabiBody)
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.clear)
                .stroke(isError ? .buttonRed : .bgGreyOverlay, lineWidth: 0.5)
                .padding(0.5)
        }
    }
}

#Preview {
    Input(text: .constant(""))
}
