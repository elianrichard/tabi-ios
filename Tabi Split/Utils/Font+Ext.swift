//
//  Font+Ext.swift
//  Tabi Split
//
//  Created by Elian Richard on 23/10/24.
//

import Foundation
import SwiftUI

extension Font {
    /// Size: 32, Font: Figtree Bold
    public static let tabiLargeTitle = Font.custom(UIConfig.Font.Name.Bold, size: UIConfig.Font.Size.LargeTitle)
    /// Size: 24, Font: Figtree Bold
    public static let tabiTitle = Font.custom(UIConfig.Font.Name.Bold, size: UIConfig.Font.Size.Title)
    /// Size: 20, Font: Figtree Semibold
    public static let tabiSubtitle = Font.custom(UIConfig.Font.Name.Semibold, size: UIConfig.Font.Size.Subtitle)
    /// Size: 17, Font: Figtree Medium
    public static let tabiHeadline = Font.custom(UIConfig.Font.Name.Medium, size: UIConfig.Font.Size.Headline)
    /// Size: 15, Font: Figtree Regular
    public static let tabiBody = Font.custom(UIConfig.Font.Name.Regular, size: UIConfig.Font.Size.Body)
    /// Size: 15, Font: Figtree Medium
    public static let tabiBody2 = Font.custom(UIConfig.Font.Name.Medium, size: UIConfig.Font.Size.Body)
}
