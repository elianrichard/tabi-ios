//
//  NuggetView.swift
//  Tabi
//
//  Created by Elian Richard on 04/10/24.
//

import SwiftUI

struct NuggetView : View {
    var text: String
    var isSelected: Bool
    
    var body: some View {
        Text("\(text)")
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(isSelected ? Color(UIColor(hex: "#C9C9C9")) : .clear)
            .foregroundStyle(.black)
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .overlay {
                RoundedRectangle(cornerRadius: 30)
                    .strokeBorder(Color(UIColor(hex: "#C9C9C9")), lineWidth: 1)
                
            }
    }
}

#Preview {
    NuggetView(text: "All", isSelected: true)
}
