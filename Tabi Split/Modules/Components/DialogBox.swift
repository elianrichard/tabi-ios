//
//  DialogBox.swift
//  Tabi Split
//
//  Created by Elian Richard on 13/11/24.
//

import SwiftUI

struct DialogBox: View {
    @State private var isShow = true
    
    var image: ImageResource?
    var icon: String?
    var iconColor: Color?
    var iconSize: CGFloat
    var text: String
    var backgroundColor: Color
    var isClosable: Bool
    
    init(icon: String, iconColor: Color, iconSize: CGFloat = 24, text: String, backgroundColor: Color = .bgBlueElevated, isClosable: Bool = true) {
        self.icon = icon
        self.iconColor = iconColor
        self.iconSize = iconSize
        self.text = text
        self.backgroundColor = backgroundColor
        self.isClosable = isClosable
    }
    
    init(image: ImageResource, iconSize: CGFloat = 24, text: String, backgroundColor: Color = .bgBlueElevated, isClosable: Bool = true) {
        self.image = image
        self.iconSize = iconSize
        self.text = text
        self.backgroundColor = backgroundColor
        self.isClosable = isClosable
    }
    
    var body: some View {
        if isShow {
            HStack (spacing: .spacingTight) {
                if let icon, let iconColor {
                    Icon(systemName: icon, color: iconColor, size: iconSize)
                } else if let image {
                    Image(image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: iconSize, maxHeight: .infinity, alignment: .center)
                }
                Text(text)
                    .font(.tabiBody)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
                if isClosable {
                    Button {
                        isShow = false
                    } label: {
                        Icon(systemName: "xmark", color: .textBlack, size: 10)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, .spacingTight)
            .padding(.horizontal, .spacingRegular)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: .radiusMedium))
        }
    }
}
