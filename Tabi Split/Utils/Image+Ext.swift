//
//  Image+Ext.swift
//  Tabi Split
//
//  Created by Elian Richard on 23/10/24.
//

import SwiftUI

extension Image {
    func iconImage (_ resource: ImageResource) -> some View {
        Image(resource).resizable().scaledToFit().frame(width: 20)
    }
}
