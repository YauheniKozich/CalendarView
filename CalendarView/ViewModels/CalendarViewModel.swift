 import Foundation

/// Реализация CalendarViewModelProtocol
/// Управляет состоянием календаря, выбранными датами и бизнес-логикой

@MainActor
final class CalendarViewModel: CalendarViewModelProtocol {
    private let _calendar: CalendarProvider
    private let baseDate: Date
    private let storage: DateStorage
    private let _dateFormatter: DateFormatterProvider

    private(set) var currentMonthOffset = 0
    private(set) var selectedDates: [Date] = []
    private(set) var days: [Date?] = []
    private(set) var calendarDays: [CalendarDay] = []

    // Кеширование для оптимизации поиска selectedDates
    private var _selectedDatesSetCache: Set<Int>?

    /// Сегодняшняя дата
    var today: Date {
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
        self._dateFormatter.calendar = calendar.foundationCalendar
        self.baseDate = _calendar.today
    }

    func load() {
        var shouldPersistDefaultSelection = false
        do {
            let loadedDates = try storage.load()
            if !loadedDates.isEmpty {
                applyLoadedDates(loadedDates)
            } else {
                setDefaultSelection()
                shouldPersistDefaultSelection = true
            }
        } catch {
            Logger.error("Failed to load dates: \(error.localizedDescription)", category: .storage)
            setDefaultSelection()
        }
        invalidateSelectedDatesSetCache()
        updateDays()

        if shouldPersistDefaultSelection {
            do {
                try storage.save(selectedDates)
            } catch {
                Logger.error("Failed to save default dates: \(error.localizedDescription)", category: .storage)
            }
        }
    }

    func save() throws {
        try storage.save(selectedDates)
    }

    func updateDays() {
        // Инвалидируем кеш selectedDatesSet при обновлении дней
        invalidateSelectedDatesSetCache()

        guard let startOfMonth = _calendar.date(from: _calendar.dateComponents([.year, .month], from: currentMonth)),
              let range = _calendar.range(of: .day, in: .month, for: startOfMonth) else {
            Logger.warning("Failed to calculate month range for \(currentMonth)", category: .calendar)
            days = []
            calendarDays = []
            return
        }

        let weekday = _calendar.component(.weekday, from: startOfMonth)
        let adjustedWeekday = (weekday - _calendar.firstWeekday + 7) % 7
        days = Array(repeating: nil, count: adjustedWeekday) + range.compactMap {
            _calendar.date(byAdding: .day, value: $0 - 1, to: startOfMonth)
        }

        calendarDays = makeCalendarDays()
    }
    
    func makeCalendarDays() -> [CalendarDay] {
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

    private func applyLoadedDates(_ loadedDates: [Date]) {
        selectedDates = normalizeSelectedDates(loadedDates)
        updateMonthOffsetForSelection()
    }

    private func normalizeSelectedDates(_ dates: [Date]) -> [Date] {
        Array(Array(Set(dates.map { _calendar.startOfDay(for: $0) })).sorted().prefix(2))
    }

    private func updateMonthOffsetForSelection() {
        if let firstDate = selectedDates.first {
            currentMonthOffset = monthOffset(from: baseDate, to: firstDate)
        }
    }

    private func setDefaultSelection() {
        selectedDates = [_calendar.startOfDay(for: today)]
        currentMonthOffset = 0
    }

    var currentMonth: Date {
        _calendar.date(byAdding: Calendar.Component.month, value: currentMonthOffset, to: baseDate) ?? baseDate
    }

    var monthFormatter: DateFormatterProvider {
        _dateFormatter
    }
    
    var dateFormatter: DateFormatterProvider {
        _dateFormatter
    }

    var calendar: CalendarProvider {
        _calendar
    }

    var selectedDatesCount: Int {
        selectedDates.count
    }

    var hasSelectedDates: Bool {
        !selectedDates.isEmpty
    }

    var firstSelectedDate: Date? {
        selectedDates.first
    }

    /// Множество выбранных дат для быстрого поиска (с кешированием)
    private var selectedDatesSet: Set<Int> {
        if let cached = _selectedDatesSetCache {
            return cached
        }

        let set = Set(selectedDates.map { date in
            dateKey(for: date)
        })

        _selectedDatesSetCache = set
        return set
    }

    /// Очищает кеш selectedDatesSet
    private func invalidateSelectedDatesSetCache() {
        _selectedDatesSetCache = nil
    }

    /// Публичный метод для очистки кеша дат (для восстановления после взрыва)
    func clearDatesCache() {
        invalidateSelectedDatesSetCache()
    }

    /// Диапазон выбранных дат (если выбрано ровно 2 даты)
    private var selectedRange: (start: Date, end: Date)? {
        guard selectedDates.count == 2 else {
            return nil
        }
        return (start: selectedDates[0], end: selectedDates[1])
    }

    /// Ключ даты для сопоставления выбранных дат
    private func dateKey(for date: Date) -> Int {
        let components = _calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return year * 10000 + month * 100 + day
    }

    /// Смещение месяцев от базовой даты до целевой даты
    private func monthOffset(from base: Date, to target: Date) -> Int {
        let baseComponents = _calendar.dateComponents([.year, .month], from: base)
        let targetComponents = _calendar.dateComponents([.year, .month], from: target)
        let baseYear = baseComponents.year ?? 0
        let baseMonth = baseComponents.month ?? 0
        let targetYear = targetComponents.year ?? 0
        let targetMonth = targetComponents.month ?? 0
        return (targetYear - baseYear) * 12 + (targetMonth - baseMonth)
    }

    func select(_ date: Date) throws {
        guard date >= today else {
            Logger.warning("Cannot select dates before today: \(date)", category: .calendar)
            return
        }

        let normalizedDate = _calendar.startOfDay(for: date)
        
        if selectedDates.contains(where: { _calendar.isDate($0, inSameDayAs: normalizedDate) }) {
            return
        }

        let previousSelection = selectedDates
        if selectedDates.count == 2 {
            selectedDates[0] = normalizedDate
            selectedDates.sort()
        } else {
            selectedDates.append(normalizedDate)
            selectedDates.sort()
        }

        invalidateSelectedDatesSetCache()
        updateDays()
        do {
            try save()
        } catch {
            selectedDates = previousSelection
            invalidateSelectedDatesSetCache()
            updateDays()
            throw error
        }
    }

    func clear() throws {
        let previousSelection = selectedDates
        let previousMonthOffset = currentMonthOffset
        setDefaultSelection()
        invalidateSelectedDatesSetCache()
        updateDays()
        do {
            try save()
        } catch {
            selectedDates = previousSelection
            currentMonthOffset = previousMonthOffset
            invalidateSelectedDatesSetCache()
            updateDays()
            throw error
        }
    }

    func isDateSelected(_ date: Date) -> Bool {
        selectedDatesSet.contains(dateKey(for: date))
    }

    func isDateInRange(_ date: Date) -> Bool {
        guard let range = selectedRange else { return false }
        let normalizedDate = _calendar.startOfDay(for: date)
        return normalizedDate > range.start && normalizedDate < range.end
    }

    func changeMonth(by delta: Int) {
        currentMonthOffset += delta
        updateDays()
    }

}
