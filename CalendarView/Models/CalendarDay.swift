//
//  CalendarDay.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 14.06.25.
//

import Foundation

public struct CalendarDay: Hashable, Sendable {
    let date: Date?
    let placeholderIndex: Int?
    let isPlaceholder: Bool
    let isSelected: Bool
    let isInRange: Bool

    init(date: Date?, placeholderIndex: Int? = nil, selectedDatesSet: Set<String>, range: (start: Date, end: Date)?, calendar: CalendarProvider) {
        self.date = date
        self.placeholderIndex = placeholderIndex
        self.isPlaceholder = (date == nil)

        guard let date else {
            isSelected = false
            isInRange = false
            return
        }

        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let dateKey = "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
        isSelected = selectedDatesSet.contains(dateKey)

        isInRange = {
            guard let range else { return false }
            let normalizedDate = calendar.startOfDay(for: date)
            return normalizedDate > range.start && normalizedDate < range.end
        }()
    }
    
    public func hash(into hasher: inout Hasher) {
        if let date = date {
            hasher.combine(date)
            hasher.combine(isSelected)
            hasher.combine(isInRange)
        } else if let index = placeholderIndex {
            hasher.combine("placeholder")
            hasher.combine(index)
        } else {
            hasher.combine("placeholder")
        }
    }
    
    public static func == (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
        if let lhsDate = lhs.date, let rhsDate = rhs.date {
            return lhsDate == rhsDate && lhs.isSelected == rhs.isSelected && lhs.isInRange == rhs.isInRange
        } else if lhs.placeholderIndex != nil || rhs.placeholderIndex != nil {
            return lhs.placeholderIndex == rhs.placeholderIndex
        }
        return false
    }
}
