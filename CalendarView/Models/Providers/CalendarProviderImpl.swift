 import Foundation

/// Реализация CalendarProvider на основе Calendar
final class CalendarProviderImpl: CalendarProvider {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    private var calendarWithCurrentTimeZone: Calendar {
        var cal = self.calendar
        cal.timeZone = TimeZone.current
        return cal
    }

    var today: Date {
        calendarWithCurrentTimeZone.startOfDay(for: Date())
    }

    func dateComponents(_ components: Set<Calendar.Component>, from date: Date) -> DateComponents {
        calendarWithCurrentTimeZone.dateComponents(components, from: date)
    }

    func date(from components: DateComponents) -> Date? {
        let cal = calendarWithCurrentTimeZone
        return cal.date(from: components)
    }

    func isDate(_ date1: Date, inSameDayAs date2: Date) -> Bool {
        calendarWithCurrentTimeZone.isDate(date1, inSameDayAs: date2)
    }

    func range(of component: Calendar.Component, in larger: Calendar.Component, for date: Date) -> Range<Int>? {
        calendarWithCurrentTimeZone.range(of: component, in: larger, for: date)
    }

    func date(byAdding component: Calendar.Component, value: Int, to date: Date) -> Date? {
        calendarWithCurrentTimeZone.date(byAdding: component, value: value, to: date)
    }

    func component(_ component: Calendar.Component, from date: Date) -> Int {
        calendarWithCurrentTimeZone.component(component, from: date)
    }

    var firstWeekday: Int {
        calendar.firstWeekday
    }

    func compare(_ date1: Date, to date2: Date, toGranularity component: Calendar.Component) -> ComparisonResult {
        calendarWithCurrentTimeZone.compare(date1, to: date2, toGranularity: component)
    }

    func startOfDay(for date: Date) -> Date {
        calendarWithCurrentTimeZone.startOfDay(for: date)
    }

    func isDateInWeekend(_ date: Date) -> Bool {
        calendarWithCurrentTimeZone.isDateInWeekend(date)
    }
}
