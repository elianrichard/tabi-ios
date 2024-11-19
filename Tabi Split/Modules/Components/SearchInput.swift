//
//  SearchInput.swift
//  Tabi Split
//
//  Created by Elian Richard on 17/11/24.
//

import SwiftUI

struct SearchInput: View {
    @Binding var text: String
    var placeholder: String = "Search"
    
    var body: some View {
        HStack (spacing: .spacingSmall) {
            Icon(systemName: "magnifyingglass", color: .textGrey, size: 16)
            TextField("", text: $text, prompt: Text("\(placeholder)").foregroundStyle(.textGrey))
            Spacer()
            Button{
                text = ""
            }label:{
                Icon(systemName: "x.circle.fill", color: .textGrey, size: 16)
            }
        }
        .padding(.spacingTight)
        .background(.uiWhite)
        .clipShape(RoundedRectangle(cornerRadius: .infinity))
        .foregroundStyle(.black)
        .font(.tabiBody)
        .overlay {
            RoundedRectangle(cornerRadius: .infinity)
                .fill(.clear)
                .stroke(.uiGray, lineWidth: 1)
                .padding(1)
        }
    }
}
