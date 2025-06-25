//
//  CalendarViewModel.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 14.06.25.
//

import Foundation
import Combine

final class CalendarViewModel {
    private let calendar = Calendar.current
    private let baseDate = Calendar.current.startOfDay(for: Date()) // фиксированная точка отсчёта
    private let storage: SelectedDatesStorage
   
    private(set) var currentMonthOffset = 0
    private(set) var selectedDates: [Date] = []
    private(set) var days: [Date?] = []
    @Published private(set) var calendarDays: [CalendarDay] = []

    var today: Date { calendar.startOfDay(for: Date()) }

    lazy var monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    init(storage: SelectedDatesStorage = UserDefaultsSelectedDatesStorage()) {
        self.storage = storage
    }

    func load() {
        let loadedDates = storage.load()
        if !loadedDates.isEmpty {
            selectedDates = loadedDates
            if let firstDate = selectedDates.first {
                let firstComponents = calendar.dateComponents([.year, .month], from: firstDate)
                let baseComponents = calendar.dateComponents([.year, .month], from: baseDate)
                if let firstYear = firstComponents.year, let firstMonth = firstComponents.month,
                   let baseYear = baseComponents.year, let baseMonth = baseComponents.month {
                    currentMonthOffset = (firstYear - baseYear) * 12 + (firstMonth - baseMonth)
                }
            }
        } else {
            selectedDates = [today]
            storage.save(selectedDates)
            currentMonthOffset = 0
        }
        updateDays()
    }

    func save() {
        storage.save(selectedDates)
    }

    func updateDays() {
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)),
              let range = calendar.range(of: .day, in: .month, for: startOfMonth) else {
            days = []
            return
        }

        let weekday = calendar.component(.weekday, from: startOfMonth)
        let adjustedWeekday = (weekday - calendar.firstWeekday + 7) % 7
        days = Array(repeating: nil, count: adjustedWeekday) + range.compactMap {
            calendar.date(byAdding: .day, value: $0 - 1, to: startOfMonth)
        }
        calendarDays = makeCalendarDays()
    }
    
    func makeCalendarDays() -> [CalendarDay] {
        let range = selectedRange
        return days.map {
            CalendarDay(date: $0, today: today, selectedDates: selectedDates, range: range)
        }
    }

    var currentMonth: Date {
        calendar.date(byAdding: .month, value: currentMonthOffset, to: baseDate) ?? baseDate
    }

    func select(_ date: Date) {
        guard !selectedDates.contains(where: { calendar.isDate($0, inSameDayAs: date) }) else { return }

        if selectedDates.count == 2 {
            selectedDates = [date]
        } else {
            selectedDates.append(date)
        }

        save()
        updateDays()
    }

    func clear() {
        selectedDates = [today]
        currentMonthOffset = 0
        save()
        updateDays()
    }

    func isDateSelected(_ date: Date) -> Bool {
        selectedDates.contains(where: { calendar.isDate($0, inSameDayAs: date) })
    }

    func isDateInRange(_ date: Date) -> Bool {
        guard let range = selectedRange else { return false }
        return calendar.compare(date, to: range.start, toGranularity: .day) == .orderedDescending &&
               calendar.compare(date, to: range.end, toGranularity: .day) == .orderedAscending
    }

    func changeMonth(by delta: Int) {
        currentMonthOffset += delta
        updateDays()
    }

    private var selectedRange: (start: Date, end: Date)? {
        guard selectedDates.count == 2 else { return nil }
        return (min(selectedDates[0], selectedDates[1]), max(selectedDates[0], selectedDates[1]))
    }
}
