//
//  WeekStore.swift
//  CalendarToDo
//
//  Created by Justin Laiti on 1/14/24.
//

import Foundation

class WeekStore: ObservableObject {
    // dates of the current week to display
    @Published var currentWeek: Week?
    @Published var selectedDate: Date?

    init() {
        setCurrentWeek()
    }

    // set the current week based on today
    private func setCurrentWeek() {
        let today = Date()
        currentWeek = week(for: today)
    }

    // set the Week based on a given date
    private func week(for date: Date) -> Week {
        // creates the result which is an empty date array
        var result: [Date] = .init()
        
        // get the start of the week
        guard let startOfWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) else { return Week(dates: [], referenceDate: date) }

        // based on the start of the week add 6 days and append the weeks into the result
        (0...6).forEach { day in
            if let weekday = Calendar.current.date(byAdding: .day, value: day, to: startOfWeek) {
                result.append(weekday)
            }
        }

        return Week(dates: result, referenceDate: date)
    }
    
    func adjustWeek(by: Int) {
        if let currentReferenceDate = currentWeek?.referenceDate {
            let newReferenceDate = Calendar.current.date(byAdding: .weekOfYear, value: by, to: currentReferenceDate)
            currentWeek = week(for: newReferenceDate ?? currentReferenceDate)
        }
    }
}
