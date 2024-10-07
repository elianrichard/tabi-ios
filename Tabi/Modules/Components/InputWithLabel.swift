//
//  InputWithLabel.swift
//  Tabi
//
//  Created by ahmad naufal alfakhar on 03/10/24.
//

import SwiftUI

struct InputWithLabel: View {
    var label: String = "Label"
    var placeholder: String = ""
    
    var body: some View {
        VStack(alignment: .leading){
            Text(label)
                .font(.system(size: 16))
                .padding(.horizontal)
            Input(placeholder: placeholder)
        }
    }
}

#Preview {
    InputWithLabel()
}
