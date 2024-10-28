//
//  Font+Ext.swift
//  Tabi Split
//
//  Created by Elian Richard on 23/10/24.
//

import SwiftUI

extension Font {
    static let tabiLargeTitle = Font.custom(UIConfig.Font.Name.Bold, size: UIConfig.Font.Size.LargeTitle)
    static let tabiTitle = Font.custom(UIConfig.Font.Name.Bold, size: UIConfig.Font.Size.Title)
    static let tabiSubtitle = Font.custom(UIConfig.Font.Name.Semibold, size: UIConfig.Font.Size.Subtitle)
    static let tabiHeadline = Font.custom(UIConfig.Font.Name.Medium, size: UIConfig.Font.Size.Headline)
    static let tabiBody = Font.custom(UIConfig.Font.Name.Regular, size: UIConfig.Font.Size.Body)
}
