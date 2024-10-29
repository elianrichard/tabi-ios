//
//  Icon.swift
//  Tabi Split
//
//  Created by Elian Richard on 23/10/24.
//

import SwiftUI

struct Icon: View {
    var resource: ImageResource?
    var systemName: String?
    var color: Color
    var size: CGFloat
    
    init(_ resource: ImageResource, color: Color = .textBlack, size: CGFloat = 24) {
        self.resource = resource
        self.size = size
        self.systemName = nil
        self.color = color
    }
    
    init(systemName: String, color: Color = .textBlack , size: CGFloat = 24) {
        self.resource = nil
        self.size = size
        self.systemName = systemName
        self.color = color
    }
    
    var body: some View {
        if let imageResource = resource {
            Image(imageResource)
                .resizable()
                .scaledToFit()
                .frame(width: size)
                .foregroundStyle(color)
                
        } else if let systemResource = systemName {
            Image(systemName: systemResource)
                .resizable()
                .scaledToFit()
                .frame(width: size)
                .foregroundStyle(color)
        }
    }
}

#Preview {
    Icon(.eyeIcon)
}
