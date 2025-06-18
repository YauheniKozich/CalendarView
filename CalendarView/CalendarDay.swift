//
//  CalendarDay.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 14.06.25.
//

import Foundation

struct CalendarDay: Hashable {
    let id = UUID()
    let date: Date?
    let isPlaceholder: Bool
    let isSelected: Bool
    let isInRange: Bool

    init(date: Date?, today: Date, selectedDates: [Date], range: (Date, Date)?) {
        self.date = date
        self.isPlaceholder = (date == nil)

        guard let date else {
            isSelected = false
            isInRange = false
            return
        }

        isSelected = selectedDates.contains(where: { Calendar.current.isDate($0, inSameDayAs: date) })
        isInRange = {
            guard let range else { return false }
            return date > range.0 && date < range.1
        }()
    }
}
