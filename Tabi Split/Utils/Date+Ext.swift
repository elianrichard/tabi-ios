//
//  Date+Ext.swift
//  Tabi
//
//  Created by Elian Richard on 30/09/24.
//

import Foundation

enum DateComponentEnum {
    case minute, hour, day, week, year
}

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
    
    func toTimeElapsedText() -> String {
        let currentDate = Date()
        let duration: TimeInterval = currentDate.timeIntervalSince(self).rounded(.towardZero)
        
        if (duration < Date.secondsInMinute) {
            return "Now"
        } else if (duration < Date.secondsInMinute * 2) {
            return "A minute ago"
        } else if (duration < Date.secondsInHour) {
            return "\(Date.secondsConversion(seconds: duration, component: .minute)) mins ago"
        } else if (duration < Date.secondsInHour * 2) {
            return "An hour ago"
        } else if (duration < Date.secondsInDay) {
            return "\(Date.secondsConversion(seconds: duration, component: .hour)) hrs ago"
        } else if (duration < Date.secondsInDay * 2) {
            return "A day ago"
        } else if (duration < Date.secondsInWeek) {
            return "\(Date.secondsConversion(seconds: duration, component: .day)) days ago"
        } else if (duration < Date.secondsInWeek * 2) {
            return "A week ago"
        } else if (duration < Date.secondsInYear) {
            return "\(Date.secondsConversion(seconds: duration, component: .week)) weeks ago"
        } else if (duration < Date.secondsInYear * 2) {
            return "A year ago"
        } else {
            return "\(Date.secondsConversion(seconds: duration, component: .year)) years ago"
        }
    }
    
    static func secondsConversion(seconds: Double, component: DateComponentEnum) -> Int {
        switch component {
        case .minute:
            return Int(seconds / Date.secondsInMinute)
        case .hour:
            return Int(seconds / Date.secondsInHour)
        case .day:
            return Int(seconds / Date.secondsInDay)
        case .week:
            return Int(seconds / Date.secondsInWeek)
        case .year:
            return Int(seconds / Date.secondsInYear)
        }
    }
    
    static let secondsInYear: Double = 31_556_952
    static let secondsInWeek: Double = 604_800
    static let secondsInDay: Double = 86_400
    static let secondsInHour: Double = 3_600
    static let secondsInMinute: Double = 60
}
