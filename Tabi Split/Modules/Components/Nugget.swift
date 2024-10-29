//
//  NuggetView.swift
//  Tabi
//
//  Created by Elian Richard on 04/10/24.
//

import SwiftUI

struct Nugget : View {
    var text: String
    var isSelected: Bool
    
    var body: some View {
        Text("\(text)")
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .background(isSelected ? .buttonBlueSelected : .clear)
            .foregroundStyle(.black)
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .overlay {
                RoundedRectangle(cornerRadius: 30)
                    .strokeBorder(isSelected ? .buttonBlue : .uiGray, lineWidth: 1)
            }
    }
}

#Preview {
    Nugget(text: "All", isSelected: true)
}
