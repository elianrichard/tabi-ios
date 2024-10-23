//
//  Icon.swift
//  Tabi Split
//
//  Created by Elian Richard on 23/10/24.
//

import SwiftUI

struct Icon: View {
    var resource: ImageResource
    
    init(_ resource: ImageResource) {
        self.resource = resource
    }
    
    var body: some View {
        Image(resource)
            .resizable()
            .scaledToFit()
            .frame(width: 20)
    }
}

#Preview {
    Icon(.eyeIcon)
}
