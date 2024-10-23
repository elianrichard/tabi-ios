//
//  CGPoint+Ext.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 16/10/24.
//

import Foundation

extension CGPoint {
    func scaled(to size: CGSize) -> CGPoint {
        return CGPoint(x: self.x * size.width, y: self.y * size.height)
    }
}
