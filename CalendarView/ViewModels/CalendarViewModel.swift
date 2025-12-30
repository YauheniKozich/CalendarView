//
//  CalendarViewModel.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 14.06.25.
//

import Foundation
import Combine

/// Реализация CalendarViewModelProtocol
/// Управляет состоянием календаря, выбранными датами и бизнес-логикой
@MainActor
public final class CalendarViewModel: CalendarViewModelProtocol, ObservableObject {
    private let _calendar: CalendarProvider
    private let baseDate: Date
    private let storage: DateStorage
    private let _dateFormatter: DateFormatterProvider

    private(set) var currentMonthOffset = 0
    private(set) var selectedDates: [Date] = []
    private(set) var days: [Date?] = []

    // Кеширование для оптимизации поиска selectedDates
    private var _selectedDatesSetCache: Set<String>?

    private let _calendarDaysSubject = CurrentValueSubject<[CalendarDay], Never>([])
    public var calendarDays: [CalendarDay] {
        _calendarDaysSubject.value
    }
    public var calendarDaysPublisher: AnyPublisher<[CalendarDay], Never> { _calendarDaysSubject.eraseToAnyPublisher() }

    /// Сегодняшняя дата
    public var today: Date {
        _calendar.today
    }

    init(
        calendar: CalendarProvider,
        storage: DateStorage,
        dateFormatter: DateFormatterProvider
    ) {
        self._calendar = calendar
        self.storage = storage
        self._dateFormatter = dateFormatter
        self.baseDate = _calendar.today
    }

    public func load() {
        do {
            let loadedDates = try storage.load()
            if !loadedDates.isEmpty {
                selectedDates = loadedDates.map { _calendar.startOfDay(for: $0) }.sorted()
            } else {
                selectedDates = [today]
                try storage.save(selectedDates)
                currentMonthOffset = 0
            }
        } catch {
            Logger.error("Failed to load dates: \(error.localizedDescription)", category: .storage)
            selectedDates = [_calendar.startOfDay(for: today)]
            currentMonthOffset = 0
        }
        invalidateSelectedDatesSetCache()
        updateDays()
    }

    @MainActor
    public func loadAsync() async throws {
        do {
            let loadedDates = try await storage.loadAsync()
        if !loadedDates.isEmpty {
            selectedDates = loadedDates.map { _calendar.startOfDay(for: $0) }.sorted()
        } else {
                selectedDates = [today]
                try await storage.saveAsync(selectedDates)
                currentMonthOffset = 0
            }

            updateDays()

        } catch {
            Logger.error("Failed to load dates asynchronously: \(error.localizedDescription)", category: .storage)
            selectedDates = [today]
            currentMonthOffset = 0
            updateDays()
            throw error
        }
        invalidateSelectedDatesSetCache()
    }


    public func save() {
        do {
            try storage.save(selectedDates)
        } catch {
            Logger.error("Failed to save dates: \(error.localizedDescription)", category: .storage)
        }
    }

    @MainActor
    public func saveAsync() async throws {
        try await storage.saveAsync(selectedDates)
    }

    public func updateDays() {
        // Инвалидируем кеш selectedDatesSet при обновлении дней
        invalidateSelectedDatesSetCache()

        guard let startOfMonth = _calendar.date(from: _calendar.dateComponents([.year, .month], from: currentMonth)),
              let range = _calendar.range(of: .day, in: .month, for: startOfMonth) else {
            Logger.warning("Failed to calculate month range for \(currentMonth)", category: .calendar)
            days = []
            _calendarDaysSubject.send([])
            return
        }

        let weekday = _calendar.component(.weekday, from: startOfMonth)
        let adjustedWeekday = (weekday - _calendar.firstWeekday + 7) % 7
        days = Array(repeating: nil, count: adjustedWeekday) + range.compactMap {
            _calendar.date(byAdding: .day, value: $0 - 1, to: startOfMonth)
        }

        let newCalendarDays = makeCalendarDays()
        _calendarDaysSubject.send(newCalendarDays)
    }
    
    public func makeCalendarDays() -> [CalendarDay] {
        let range = selectedRange
        let selectedDatesSet = self.selectedDatesSet
        var placeholderIndex = 0
        return days.map { date -> CalendarDay in
            if date == nil {
                let index = placeholderIndex
                placeholderIndex += 1
                return CalendarDay(date: nil, placeholderIndex: index, selectedDatesSet: selectedDatesSet, range: range, calendar: _calendar)
            } else {
                return CalendarDay(date: date, selectedDatesSet: selectedDatesSet, range: range, calendar: _calendar)
            }
        }
    }

    public var currentMonth: Date {
        _calendar.date(byAdding: Calendar.Component.month, value: currentMonthOffset, to: baseDate) ?? baseDate
    }

    public var monthFormatter: DateFormatterProvider {
        _dateFormatter
    }
    
    public var dateFormatter: DateFormatterProvider {
        _dateFormatter
    }

    public var calendar: CalendarProvider {
        _calendar
    }

    public var selectedDatesCount: Int {
        selectedDates.count
    }

    public var hasSelectedDates: Bool {
        !selectedDates.isEmpty
    }

    public var firstSelectedDate: Date? {
        selectedDates.first
    }

    /// Множество выбранных дат для быстрого поиска (с кешированием)
    private var selectedDatesSet: Set<String> {
        if let cached = _selectedDatesSetCache {
            return cached
        }

        let set = Set(selectedDates.map { date in
            let components = _calendar.dateComponents([.year, .month, .day], from: date)
            return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
        })

        _selectedDatesSetCache = set
        return set
    }

    /// Очищает кеш selectedDatesSet
    private func invalidateSelectedDatesSetCache() {
        _selectedDatesSetCache = nil
    }

    /// Публичный метод для очистки кеша дат (для восстановления после взрыва)
    public func clearDatesCache() {
        invalidateSelectedDatesSetCache()
    }

    /// Диапазон выбранных дат (если выбрано ровно 2 даты)
    private var selectedRange: (start: Date, end: Date)? {
        guard selectedDates.count == 2 else {
            return nil
        }
        return (start: selectedDates[0], end: selectedDates[1])
    }

    public func select(_ date: Date) {
        guard date.timeIntervalSince1970 > 0 else {
            Logger.warning("Invalid date provided for selection", category: .calendar)
            return
        }

        guard date >= today else {
            Logger.warning("Cannot select dates before today: \(date)", category: .calendar)
            return
        }

        let normalizedDate = _calendar.startOfDay(for: date)
        
        if selectedDates.contains(where: { _calendar.isDate($0, inSameDayAs: normalizedDate) }) {
            return
        }

        if selectedDates.count == 2 {
            selectedDates[0] = normalizedDate
            selectedDates.sort()
        } else {
            selectedDates.append(normalizedDate)
            selectedDates.sort()
        }

        invalidateSelectedDatesSetCache()
        updateDays()
        save()
    }

    public func clear() {
        selectedDates = [_calendar.startOfDay(for: today)]
        currentMonthOffset = 0
        invalidateSelectedDatesSetCache()
        save()
        updateDays()
    }

    public func isDateSelected(_ date: Date) -> Bool {
        let components = _calendar.dateComponents([.year, .month, .day], from: date)
        let dateKey = "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
        return selectedDatesSet.contains(dateKey)
    }

    public func isDateInRange(_ date: Date) -> Bool {
        guard let range = selectedRange else { return false }
        let normalizedDate = _calendar.startOfDay(for: date)
        return normalizedDate > range.start && normalizedDate < range.end
    }

    public func changeMonth(by delta: Int) {
        currentMonthOffset += delta
        updateDays()
    }

}
