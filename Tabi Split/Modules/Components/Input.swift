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
    
    var body: some View {
        HStack {
            if isSecure {
                SecureField("", text: $text,
                            prompt: Text(placeholder).foregroundStyle(.textGrey))
            } else {
                TextField("", text: $text,
                          prompt: Text(placeholder).foregroundStyle(.textGrey))
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
                .stroke(.bgGreyOverlay, lineWidth: 0.5)
        }
    }
}

#Preview {
    Input(text: .constant(""))
}
