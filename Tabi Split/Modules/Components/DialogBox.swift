//
//  DialogBox.swift
//  Tabi Split
//
//  Created by Elian Richard on 13/11/24.
//

import SwiftUI

struct DialogBox: View {
    @State private var isShow = true
    
    var icon: String
    var iconColor: Color
    var text: String
    var backgroundColor: Color
    
    var body: some View {
        if isShow {
            HStack (spacing: .spacingTight) {
                Icon(systemName: icon, color: iconColor)
                Text(text)
                    .font(.tabiBody)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
                Button {
                    isShow = false
                } label: {
                    Icon(systemName: "xmark", color: .textBlack, size: 10)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, .spacingTight)
            .padding(.horizontal, .spacingRegular)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: .radiusMedium))
        }
    }
}
