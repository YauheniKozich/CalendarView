 import XCTest
@testable import CalendarView

@MainActor
final class CalendarViewModelRangeTests: XCTestCase {
    private var viewModel: CalendarViewModel!
    private var mockCalendar: MockCalendarProvider!
    private var mockStorage: MockDateStorage!
    private var mockDateFormatter: MockDateFormatterProvider!

    override func setUp() async throws {
        mockCalendar = MockCalendarProvider()
        mockStorage = MockDateStorage()
        mockDateFormatter = MockDateFormatterProvider()
        viewModel = CalendarViewModel(
            calendar: mockCalendar,
            storage: mockStorage,
            dateFormatter: mockDateFormatter
        )
    }

    override func tearDown() async throws {
        viewModel = nil
        mockCalendar = nil
        mockStorage = nil
        mockDateFormatter = nil
    }

    @MainActor
    func testRangeSelection() {
        let date1 = Date(timeIntervalSince1970: 1735689600)
        let date2 = Date(timeIntervalSince1970: 1735862400)
        let date3 = Date(timeIntervalSince1970: 1735948800)
        let dateInRange = Date(timeIntervalSince1970: 1735776000)

        viewModel.select(date1)
        XCTAssertEqual(viewModel.selectedDatesCount, 1)
        XCTAssertTrue(viewModel.isDateSelected(date1))
        XCTAssertFalse(viewModel.isDateInRange(dateInRange))

        viewModel.select(date2)
        XCTAssertEqual(viewModel.selectedDatesCount, 2)
        XCTAssertTrue(viewModel.isDateSelected(date1))
        XCTAssertTrue(viewModel.isDateSelected(date2))
        XCTAssertTrue(viewModel.isDateInRange(dateInRange))

        viewModel.select(date3)
        XCTAssertEqual(viewModel.selectedDatesCount, 2)
        XCTAssertFalse(viewModel.isDateSelected(date1))
        XCTAssertTrue(viewModel.isDateSelected(date2))
        XCTAssertTrue(viewModel.isDateSelected(date3))
        XCTAssertFalse(viewModel.isDateInRange(dateInRange))
    }

    @MainActor
    func testRangeBoundaries() {
        let startDate = Date(timeIntervalSince1970: 1735689600)
        let endDate = Date(timeIntervalSince1970: 1735862400)

        viewModel.select(startDate)
        viewModel.select(endDate)

        XCTAssertFalse(viewModel.isDateInRange(startDate))
        XCTAssertFalse(viewModel.isDateInRange(endDate))

        let middleDate = Date(timeIntervalSince1970: 1735776000)
        XCTAssertTrue(viewModel.isDateInRange(middleDate))
    }

    @MainActor
    func testCalendarDaysIncludeRange() {
        let date1 = Date(timeIntervalSince1970: 1735689600)
        let date2 = Date(timeIntervalSince1970: 1735862400)

        viewModel.select(date1)
        viewModel.select(date2)

        let calendarDays = viewModel.makeCalendarDays()
        let dateDays = calendarDays.filter { $0.date != nil }
        let rangeDays = dateDays.filter { $0.isInRange }

        XCTAssertFalse(rangeDays.isEmpty, "Should have days in range when 2 dates are selected")

        let selectedRangeDays = dateDays.filter { $0.isSelected && $0.isInRange }
        XCTAssertTrue(selectedRangeDays.isEmpty, "Selected dates should not be marked as in range")
    }

    @MainActor
    func testSingleDateNoRange() {
        let date = Date(timeIntervalSince1970: 1735689600)

        viewModel.select(date)

        XCTAssertEqual(viewModel.selectedDatesCount, 1)
        XCTAssertFalse(viewModel.isDateInRange(date))

        let calendarDays = viewModel.makeCalendarDays()
        let dateDays = calendarDays.filter { $0.date != nil }
        let rangeDays = dateDays.filter { $0.isInRange }
        XCTAssertTrue(rangeDays.isEmpty, "Should have no days in range when only 1 date is selected")
    }

    @MainActor
    func testSelectedDatesPersistAndMonthRestoresOnLoad() {
        let storedDate1 = Date(timeIntervalSince1970: 1740787200)
        let storedDate2 = Date(timeIntervalSince1970: 1741219200)
        mockStorage.store(dates: [storedDate2, storedDate1])

        viewModel.load()

        XCTAssertEqual(viewModel.selectedDatesCount, 2)
        XCTAssertTrue(viewModel.isDateSelected(storedDate1))
        XCTAssertTrue(viewModel.isDateSelected(storedDate2))

        let components = mockCalendar.dateComponents([.year, .month], from: viewModel.currentMonth)
        XCTAssertEqual(components.year, 2025)
        XCTAssertEqual(components.month, 3)
    }

    @MainActor
    func testChangeMonthShiftsCurrentMonth() {
        let initialMonth = viewModel.currentMonth
        viewModel.changeMonth(by: 1)
        let nextMonth = viewModel.currentMonth

        XCTAssertEqual(
            mockCalendar.compare(initialMonth, to: nextMonth, toGranularity: .month),
            .orderedAscending
        )

        viewModel.changeMonth(by: -1)
        let backToInitial = viewModel.currentMonth
        XCTAssertEqual(
            mockCalendar.compare(initialMonth, to: backToInitial, toGranularity: .month),
            .orderedSame
        )
    }
}

private class MockCalendarProvider: CalendarProvider {
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        return cal
    }

    func dateComponents(_ components: Set<Calendar.Component>, from date: Date) -> DateComponents {
        calendar.dateComponents(components, from: date)
    }

    func date(from components: DateComponents) -> Date? {
        calendar.date(from: components)
    }

    func range(of smaller: Calendar.Component, in larger: Calendar.Component, for date: Date) -> Range<Int>? {
        calendar.range(of: smaller, in: larger, for: date)
    }

    func component(_ component: Calendar.Component, from date: Date) -> Int {
        calendar.component(component, from: date)
    }

    func date(byAdding component: Calendar.Component, value: Int, to date: Date) -> Date? {
        calendar.date(byAdding: component, value: value, to: date)
    }

    func isDate(_ date1: Date, inSameDayAs date2: Date) -> Bool {
        calendar.isDate(date1, inSameDayAs: date2)
    }

    func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    var today: Date {
        calendar.startOfDay(for: Date(timeIntervalSince1970: 1735689600))
    }

    var firstWeekday: Int {
        calendar.firstWeekday
    }

    func compare(_ date1: Date, to date2: Date, toGranularity component: Calendar.Component) -> ComparisonResult {
        calendar.compare(date1, to: date2, toGranularity: component)
    }

    func isDateInWeekend(_ date: Date) -> Bool {
        calendar.isDateInWeekend(date)
    }
}

private class MockDateStorage: DateStorage {
    private var storedDates: [Date] = []

    func load() throws -> [Date] {
        storedDates
    }

    func store(dates: [Date]) {
        storedDates = dates
    }

    func save(_ dates: [Date]) throws {
        storedDates = dates
    }

    func loadAsync() async throws -> [Date] {
        storedDates
    }

    func saveAsync(_ dates: [Date]) async throws {
        storedDates = dates
    }
}

private class MockDateFormatterProvider: DateFormatterProvider {
    var locale: Locale? = .current
    var dateFormat: String? = "MMMM yyyy"

    func string(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = dateFormat
        return formatter.string(from: date)
    }

    func string(from date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}
