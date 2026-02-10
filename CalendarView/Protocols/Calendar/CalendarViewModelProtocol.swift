 import Foundation

/// Протокол для ViewModel календаря
/// Определяет интерфейс для работы с календарными данными

protocol CalendarViewModelProtocol {
    var calendarDays: [CalendarDay] { get }
    var today: Date { get }
    var currentMonth: Date { get }
    var monthFormatter: DateFormatterProvider { get }
    var dateFormatter: DateFormatterProvider { get }
    var calendar: CalendarProvider { get }

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
    func clearDatesCache()

    func loadAsync() async throws
    func saveAsync() async throws
}

