//
//  Array+Ext.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 17/10/24.
//

import Foundation

extension Array where Element: Equatable {
   mutating func remove(_ element: Element) {
      self = filter { $0 != element }
   }
}
