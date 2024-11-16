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
    var callback: (() -> Void)?
    
    init(_ resource: ImageResource?, color: Color = .textBlack, size: CGFloat = 24, callback: (() -> Void)? = nil) {
        self.resource = resource
        self.size = size
        self.systemName = nil
        self.color = color
        self.callback = callback
    }
    
    init(systemName: String, color: Color = .textBlack , size: CGFloat = 24, callback: (() -> Void)? = nil) {
        self.resource = nil
        self.size = size
        self.systemName = systemName
        self.color = color
        self.callback = callback
    }
    
    var body: some View {
        if let callback {
            Button {
                callback()
            } label: {
                IconComponent(resource: resource, systemName: systemName, color: color, size: size)
                    .padding(size < 44 ? 44 - size : size)
            }
            .padding(size < 44 ? (44 - size) * -1 : size * -1)
        } else {
            IconComponent(resource: resource, systemName: systemName, color: color, size: size)
        }
    }
}

struct IconComponent: View {
    var resource: ImageResource?
    var systemName: String?
    var color: Color
    var size: CGFloat
    
    var body: some View {
        if let imageResource = resource {
            Image(imageResource)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundStyle(color)
            
        } else if let systemResource = systemName {
            Image(systemName: systemResource)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundStyle(color)
        }
    }
}

#Preview {
    Icon(.eyeIcon, color: .textBlue)
}
