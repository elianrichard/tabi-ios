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
}
