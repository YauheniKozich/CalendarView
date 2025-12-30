//
//  CalendarDay.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 14.06.25.
//

import Foundation

/// Реализация CalendarProvider на основе Calendar
internal final class CalendarProviderImpl: CalendarProvider {
    private let calendar: Calendar

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    public var today: Date {
        calendar.startOfDay(for: Date())
    }

    public func dateComponents(_ components: Set<Calendar.Component>, from date: Date) -> DateComponents {
        calendar.dateComponents(components, from: date)
    }

    public func date(from components: DateComponents) -> Date? {
        calendar.date(from: components)
    }

    public func isDate(_ date1: Date, inSameDayAs date2: Date) -> Bool {
        calendar.isDate(date1, inSameDayAs: date2)
    }

    public func range(of component: Calendar.Component, in larger: Calendar.Component, for date: Date) -> Range<Int>? {
        calendar.range(of: component, in: larger, for: date)
    }

    public func date(byAdding component: Calendar.Component, value: Int, to date: Date) -> Date? {
        calendar.date(byAdding: component, value: value, to: date)
    }

    public func component(_ component: Calendar.Component, from date: Date) -> Int {
        calendar.component(component, from: date)
    }

    public var firstWeekday: Int {
        calendar.firstWeekday
    }

    public func compare(_ date1: Date, to date2: Date, toGranularity component: Calendar.Component) -> ComparisonResult {
        calendar.compare(date1, to: date2, toGranularity: component)
    }

    public func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }
}

public struct CalendarDay: Hashable, Sendable {
    let id = UUID()
    let date: Date?
    let isPlaceholder: Bool
    let isSelected: Bool
    let isInRange: Bool

    init(date: Date?, today: Date, selectedDates: [Date], range: (start: Date, end: Date)?, calendar: CalendarProvider) {
        self.date = date
        self.isPlaceholder = (date == nil)

        guard let date else {
            isSelected = false
            isInRange = false
            return
        }

        // Оптимизированная проверка выбора даты
        let normalizedDate = calendar.startOfDay(for: date)
        isSelected = selectedDates.contains(where: { calendar.isDate($0, inSameDayAs: normalizedDate) })

        // Оптимизированная проверка диапазона
        isInRange = {
            guard let range else { return false }
            return normalizedDate > range.start && normalizedDate < range.end
        }()
    }
}
