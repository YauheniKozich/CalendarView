//
//  CalendarViewModel.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 14.06.25.
//


import Foundation
import Combine

@MainActor
public protocol CalendarViewModelProtocol: ObservableObject {
    var calendarDays: [CalendarDay] { get }
    var calendarDaysPublisher: Published<[CalendarDay]>.Publisher { get }
    var today: Date { get }
    var currentMonth: Date { get }
    var monthFormatter: DateFormatterProvider { get }
    var calendar: CalendarProvider { get }

    // Computed properties
    var selectedDatesCount: Int { get }
    var hasSelectedDates: Bool { get }
    var firstSelectedDate: Date? { get }

    func load()
    func save()
    func updateDays()
    func select(_ date: Date)
    func clear()
    func isDateSelected(_ date: Date) -> Bool
    func isDateInRange(_ date: Date) -> Bool
    func changeMonth(by delta: Int)
    func makeCalendarDays() -> [CalendarDay]

    // Async versions
    @MainActor func loadAsync() async throws
    @MainActor func saveAsync() async throws
}

@MainActor
public final class CalendarViewModel: CalendarViewModelProtocol {
    private let _calendar: CalendarProvider
    private let baseDate: Date
    private let storage: DateStorage
    private let dateFormatter: DateFormatterProvider
   
    private(set) var currentMonthOffset = 0
    private(set) var selectedDates: [Date] = []
    private(set) var days: [Date?] = []
    @Published public private(set) var calendarDays: [CalendarDay] = []

    public var calendarDaysPublisher: Published<[CalendarDay]>.Publisher { $calendarDays }

    // MARK: - Caching

    /// Кеш для currentMonth - инвалидируется при изменении offset
    private var _currentMonthCache: Date?

    /// Кеш для selectedRange - инвалидируется при изменении selectedDates
    private var _selectedRangeCache: (start: Date, end: Date)?

    /// Кеш для calendarDays - инвалидируется при изменении данных
    private var _calendarDaysCache: [CalendarDay]?

    /// Кеш для быстрого поиска выбранных дат
    private var _selectedDatesSetCache: Set<Date>?

    /// Инвалидирует все кеши при изменении состояния
    private func invalidateCaches() {
        _selectedRangeCache = nil
        _calendarDaysCache = nil
        _selectedDatesSetCache = nil
        Logger.debug("Caches invalidated", category: .calendar)
    }

    /// Кешированная сегодняшняя дата (обновляется при каждом доступе)
    public var today: Date {
        // Обновляем кеш каждый раз, так как "сегодня" может измениться
        _calendar.today
    }

    @MainActor
    init(
        calendar: CalendarProvider? = nil,
        storage: DateStorage? = nil,
        dateFormatter: DateFormatterProvider? = nil
    ) {
        let calendarProvider = calendar ?? DependencyFactories.CalendarProviderFactory.makeDefault()
        let dateStorage = storage ?? DependencyFactories.DateStorageFactory.makeDefault()
        let dateFormatterProvider = dateFormatter ?? DependencyFactories.DateFormatterFactory.makeDefault()

        self._calendar = calendarProvider
        self.storage = dateStorage
        self.dateFormatter = dateFormatterProvider
        self.baseDate = _calendar.today
    }

    public func load() {
        do {
            let loadedDates = try storage.load()
            if !loadedDates.isEmpty {
                selectedDates = loadedDates
                // Переходим к месяцу первой выбранной даты для лучшего UX
                if let firstDate = selectedDates.first {
                    navigateToMonthOf(date: firstDate)
                }
            } else {
                selectedDates = [today]
                try storage.save(selectedDates)
                currentMonthOffset = 0
            }
        } catch {
            Logger.error("Failed to load dates: \(error.localizedDescription)", category: .storage)
            selectedDates = [today]
            currentMonthOffset = 0
        }
        updateDays()
    }

    @MainActor
    public func loadAsync() async throws {
        let loadedDates = try await storage.loadAsync()
        if !loadedDates.isEmpty {
            selectedDates = loadedDates
            // Переходим к месяцу первой выбранной даты для лучшего UX
            if let firstDate = selectedDates.first {
                navigateToMonthOf(date: firstDate)
            }
        } else {
            selectedDates = [today]
            try await storage.saveAsync(selectedDates)
            currentMonthOffset = 0
        }

        await MainActor.run {
            updateDays()
        }

        Logger.info("Dates loaded asynchronously: \(loadedDates.count) dates", category: .storage)
    }

    /// Навигация к месяцу, содержащему указанную дату
    private func navigateToMonthOf(date: Date) {
        let dateComponents = _calendar.dateComponents([.year, .month], from: date)
        let baseComponents = _calendar.dateComponents([.year, .month], from: baseDate)

        guard let dateYear = dateComponents.year,
              let dateMonth = dateComponents.month,
              let baseYear = baseComponents.year,
              let baseMonth = baseComponents.month else {
            currentMonthOffset = 0
            return
        }

        currentMonthOffset = (dateYear - baseYear) * 12 + (dateMonth - baseMonth)
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
        Logger.info("Dates saved asynchronously", category: .storage)
    }

    public func updateDays() {
        Logger.debug("updateDays() called for month: \(currentMonth)", category: .calendar)

        // Инвалидируем кеш перед обновлением данных
        invalidateCaches()

        guard let startOfMonth = _calendar.date(from: _calendar.dateComponents([.year, .month], from: currentMonth)),
              let range = _calendar.range(of: .day, in: .month, for: startOfMonth) else {
            Logger.warning("Failed to calculate month range for \(currentMonth)", category: .calendar)
            days = []
            return
        }

        let weekday = _calendar.component(.weekday, from: startOfMonth)
        let adjustedWeekday = (weekday - _calendar.firstWeekday + 7) % 7
        days = Array(repeating: nil, count: adjustedWeekday) + range.compactMap {
            _calendar.date(byAdding: .day, value: $0 - 1, to: startOfMonth)
        }

        Logger.debug("Calculated \(days.count) days for month starting \(startOfMonth)", category: .calendar)
        calendarDays = makeCalendarDays()
        Logger.debug("Created \(calendarDays.count) calendar days", category: .calendar)
    }
    
    public func makeCalendarDays() -> [CalendarDay] {
        // Используем кеш для calendarDays
        if let cached = _calendarDaysCache {
            Logger.debug("Using cached calendar days (\(cached.count) items)", category: .calendar)
            return cached
        }

        Logger.debug("Creating new calendar days from \(days.count) day entries", category: .calendar)
        let range = optimizedSelectedRange
        let calendarDays = days.map {
            CalendarDay(date: $0, today: today, selectedDates: selectedDates, range: range, calendar: _calendar)
        }

        _calendarDaysCache = calendarDays
        Logger.debug("Cached \(calendarDays.count) calendar days", category: .calendar)
        return calendarDays
    }

    public var currentMonth: Date {
        if let cached = _currentMonthCache {
            return cached
        }
        let result = _calendar.date(byAdding: Calendar.Component.month, value: currentMonthOffset, to: baseDate) ?? baseDate
        _currentMonthCache = result
        return result
    }

    public var monthFormatter: DateFormatterProvider {
        dateFormatter
    }

    public var calendar: CalendarProvider {
        _calendar
    }

    // MARK: - Computed Properties для производительности

    /// Количество выбранных дат (кешируется)
    public var selectedDatesCount: Int {
        selectedDates.count
    }

    /// Есть ли выбранные даты
    public var hasSelectedDates: Bool {
        !selectedDates.isEmpty
    }

    /// Первый выбранная дата (для быстрого доступа)
    public var firstSelectedDate: Date? {
        selectedDates.first
    }

    /// Быстрый доступ к множеству выбранных дат для O(1) поиска
    private var selectedDatesSet: Set<Date> {
        if let cached = _selectedDatesSetCache {
            return cached
        }
        let set = Set(selectedDates.map { _calendar.startOfDay(for: $0) })
        _selectedDatesSetCache = set
        return set
    }

    /// Оптимизированная версия selectedRange
    private var optimizedSelectedRange: (start: Date, end: Date)? {
        if let cached = _selectedRangeCache {
            return cached
        }
        guard selectedDates.count == 2,
              let start = selectedDates.min(),
              let end = selectedDates.max() else {
            return nil
        }
        let range = (start: _calendar.startOfDay(for: start), end: _calendar.startOfDay(for: end))
        _selectedRangeCache = range
        return range
    }

    public func select(_ date: Date) {
        // Валидация даты - проверяем что дата не nil и валидна
        guard date.timeIntervalSince1970 > 0 else {
            Logger.warning("Invalid date provided for selection", category: .calendar)
            // В будущем можно добавить callback для обработки ошибок
            return
        }

        guard date >= today else {
            Logger.warning("Cannot select past dates: \(date)", category: .calendar)
            // В будущем можно добавить callback для обработки ошибок
            return
        }

        guard !selectedDates.contains(where: { _calendar.isDate($0, inSameDayAs: date) }) else {
            Logger.debug("Date already selected: \(date)", category: .calendar)
            return
        }

        if selectedDates.count == 2 {
            // Если выбрано 2 даты, заменяем первую на новую
            selectedDates[0] = date
        } else {
            // Если выбрана 1 дата или ни одной, добавляем новую
            selectedDates.append(date)
        }

        // Инвалидируем кеш при изменении дат
        invalidateCaches()

        save()
        updateDays()
        Logger.info("Date selected: \(date)", category: .calendar)
    }

    public func clear() {
        selectedDates = [today]
        currentMonthOffset = 0
        invalidateCaches() // Инвалидируем все кеши
        save()
        updateDays()
    }

    public func isDateSelected(_ date: Date) -> Bool {
        // O(1) поиск вместо O(n) благодаря Set
        selectedDatesSet.contains(_calendar.startOfDay(for: date))
    }

    public func isDateInRange(_ date: Date) -> Bool {
        guard let range = optimizedSelectedRange else { return false }
        let normalizedDate = _calendar.startOfDay(for: date)
        return normalizedDate > range.start && normalizedDate < range.end
    }

    public func changeMonth(by delta: Int) {
        currentMonthOffset += delta
        _currentMonthCache = nil // Инвалидируем кеш currentMonth
        updateDays()
    }

    private var selectedRange: (start: Date, end: Date)? {
        if let cached = _selectedRangeCache {
            return cached
        }
        guard selectedDates.count == 2, let start = selectedDates.min(), let end = selectedDates.max() else { return nil }
        let range = (start, end)
        _selectedRangeCache = range
        return range
    }
}
