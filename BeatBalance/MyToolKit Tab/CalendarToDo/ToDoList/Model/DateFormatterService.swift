//
//  DateFormatterService.swift
//  CalendarToDo
//
//  Created by Justin Laiti on 1/31/24.
//

import Foundation

struct DateFormatterService {
    
    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }()
    
    private static let dayOfWeekFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()
    
    private static let dayOfMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    private static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()
    
    static func monthString(from date: Date) -> String {
        return monthFormatter.string(from: date)
    }
    
    static func dayOfWeekLetter(from date: Date) -> String {
        let weekday = dayOfWeekFormatter.string(from: date)
        return String(weekday.prefix(1))
    }
    
    static func dayOfMonthString(from date: Date) -> String {
        return dayOfMonthFormatter.string(from: date)
    }
    
    static func fullDateString(from date: Date) -> String {
        return fullDateFormatter.string(from: date)
    }
}
