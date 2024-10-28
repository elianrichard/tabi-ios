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
            static let Title1: CGFloat = 24
            static let Title2: CGFloat = 20
            static let Headline: CGFloat = 17
            static let Body: CGFloat = 15
        }
    }
    
    struct Spacing {
        static let XLarge: CGFloat = 64
        static let Large: CGFloat = 36
        static let Medium: CGFloat = 24
        static let Regular: CGFloat = 16
        static let Tight: CGFloat = 12
        static let Small: CGFloat = 8
        static let XSmall: CGFloat = 4
    }

    struct Radius {
        static let Large: CGFloat = 16
        static let Medium: CGFloat = 8
        static let Small: CGFloat = 4
    }
}
