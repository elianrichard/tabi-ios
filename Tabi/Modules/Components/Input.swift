//
//  Input.swift
//  Tabi
//
//  Created by ahmad naufal alfakhar on 03/10/24.
//

import SwiftUI

struct Input: View {
    var placeholder: String = ""
    @State var text = ""
    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .background(Color.gray.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .padding(.horizontal)
    }
}

#Preview {
    Input()
}
