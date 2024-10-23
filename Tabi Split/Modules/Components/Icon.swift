//
//  Icon.swift
//  Tabi Split
//
//  Created by Elian Richard on 23/10/24.
//

import SwiftUI

struct Icon: View {
    var resource: ImageResource
    var size: CGFloat = 20
    
    init(_ resource: ImageResource) {
        self.resource = resource
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
