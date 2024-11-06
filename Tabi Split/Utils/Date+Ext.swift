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
    
    init(dateString:String) {
          let dateStringFormatter = DateFormatter()
          dateStringFormatter.dateFormat = "yyyy-MM-dd"
          let date = dateStringFormatter.date(from: dateString)
          if let date = date {
              self.self = date
          } else {
              self.self = Date()
          }
    }
    
    func yesterday() -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: -1, to: self) ?? Date()
    }
    
    func toProperText() -> String {
        let calendar = Calendar.current
        if (calendar.isDateInToday(self)) {
            return "Today"
        } else if (calendar.isDateInYesterday(self)) {
            return "Yesterday"
        } else {
            return customDateFormat("dd MMM").string(from: self)
        }
    }
}
