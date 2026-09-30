 import Foundation

/// Реализация CalendarProvider на основе Calendar
final class CalendarProviderImpl: CalendarProvider {
    private let calendar: Calendar

    init(calendar: Calendar = .autoupdatingCurrent) {
        self.calendar = calendar
    }

    var foundationCalendar: Calendar { calendar }

    var today: Date {
        calendar.startOfDay(for: Date())
    }

    func dateComponents(_ components: Set<Calendar.Component>, from date: Date) -> DateComponents {
        calendar.dateComponents(components, from: date)
    }

    func date(from components: DateComponents) -> Date? {
        calendar.date(from: components)
    }

    func isDate(_ date1: Date, inSameDayAs date2: Date) -> Bool {
        calendar.isDate(date1, inSameDayAs: date2)
    }

    func range(of component: Calendar.Component, in larger: Calendar.Component, for date: Date) -> Range<Int>? {
        calendar.range(of: component, in: larger, for: date)
    }

    func date(byAdding component: Calendar.Component, value: Int, to date: Date) -> Date? {
        calendar.date(byAdding: component, value: value, to: date)
    }

    func component(_ component: Calendar.Component, from date: Date) -> Int {
        calendar.component(component, from: date)
    }

    var firstWeekday: Int {
        calendar.firstWeekday
    }

    var shortWeekdaySymbols: [String] {
        calendar.shortWeekdaySymbols
    }

    func compare(_ date1: Date, to date2: Date, toGranularity component: Calendar.Component) -> ComparisonResult {
        calendar.compare(date1, to: date2, toGranularity: component)
    }

    func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    func isDateInWeekend(_ date: Date) -> Bool {
        calendar.isDateInWeekend(date)
    }
}
