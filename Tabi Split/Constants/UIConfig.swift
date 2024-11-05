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
            /// Size: 32
            static let LargeTitle: CGFloat = 32
            /// Size: 24
            static let Title: CGFloat = 24
            /// Size: 20
            static let Subtitle: CGFloat = 20
            /// Size: 17
            static let Headline: CGFloat = 17
            /// Size: 15
            static let Body: CGFloat = 15
        }
    }
    
    struct Spacing {
        /// Spacing: 64
        static let XLarge: CGFloat = 64
        /// Spacing: 36
        static let Large: CGFloat = 36
        /// Spacing: 24
        static let Medium: CGFloat = 24
        /// Spacing: 16
        static let Regular: CGFloat = 16
        /// Spacing: 12
        static let Tight: CGFloat = 12
        /// Spacing: 8
        static let Small: CGFloat = 8
        /// Spacing: 4
        static let XSmall: CGFloat = 4
    }

    struct Radius {
        static let Large: CGFloat = 24
        static let Medium: CGFloat = 16
        static let Small: CGFloat = 12
    }
}
