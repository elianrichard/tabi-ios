//
//  Icon.swift
//  Tabi Split
//
//  Created by Elian Richard on 23/10/24.
//

import SwiftUI

struct Icon: View {
    var resource: ImageResource
    var size: CGFloat
    
    init(_ resource: ImageResource, size: CGFloat = 20) {
        self.resource = resource
        self.size = size
    }
    
    var body: some View {
        Image(resource)
            .resizable()
            .scaledToFit()
            .frame(width: size)
    }
}

#Preview {
    Icon(.eyeIcon)
}
