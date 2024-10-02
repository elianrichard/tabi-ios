//
//  Date+Ext.swift
//  Tabi
//
//  Created by Elian Richard on 30/09/24.
//

import Foundation

extension Date {
    func customDateFormat(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter
    }
}
