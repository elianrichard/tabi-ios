//
//  UIConfig.swift
//  Tabi
//
//  Created by Elian Richard on 30/09/24.
//

import Foundation

struct UIConfig {
    struct Font {
        struct Name {
            static let Bold = "Figtree-Bold"
            static let Semibold = "Figtree-SemiBold"
            static let Medium = "Figtree-Medium"
            static let Regular = "Figtree-Regular"
        }
        
        struct Size {
            static let LargeTitle: CGFloat = 32
            static let Title: CGFloat = 24
            static let Subtitle: CGFloat = 20
            static let Headline: CGFloat = 17
            static let Body: CGFloat = 15
        }
    }
    
    struct Spacing {
        static let Large: CGFloat = 48
        static let Medium: CGFloat = 24
        static let Small: CGFloat = 12
    }
}
