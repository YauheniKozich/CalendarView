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
    func testRangeSelection() throws {
        let date1 = Date(timeIntervalSince1970: 1735689600)
        let date2 = Date(timeIntervalSince1970: 1735862400)
        let date3 = Date(timeIntervalSince1970: 1735948800)
        let dateInRange = Date(timeIntervalSince1970: 1735776000)

        try viewModel.select(date1)
        XCTAssertEqual(viewModel.selectedDatesCount, 1)
        XCTAssertTrue(viewModel.isDateSelected(date1))
        XCTAssertFalse(viewModel.isDateInRange(dateInRange))

        try viewModel.select(date2)
        XCTAssertEqual(viewModel.selectedDatesCount, 2)
        XCTAssertTrue(viewModel.isDateSelected(date1))
        XCTAssertTrue(viewModel.isDateSelected(date2))
        XCTAssertTrue(viewModel.isDateInRange(dateInRange))

        try viewModel.select(date3)
        XCTAssertEqual(viewModel.selectedDatesCount, 2)
        XCTAssertFalse(viewModel.isDateSelected(date1))
        XCTAssertTrue(viewModel.isDateSelected(date2))
        XCTAssertTrue(viewModel.isDateSelected(date3))
        XCTAssertFalse(viewModel.isDateInRange(dateInRange))
    }

    @MainActor
    func testRangeBoundaries() throws {
        let startDate = Date(timeIntervalSince1970: 1735689600)
        let endDate = Date(timeIntervalSince1970: 1735862400)

        try viewModel.select(startDate)
        try viewModel.select(endDate)

        XCTAssertFalse(viewModel.isDateInRange(startDate))
        XCTAssertFalse(viewModel.isDateInRange(endDate))

        let middleDate = Date(timeIntervalSince1970: 1735776000)
        XCTAssertTrue(viewModel.isDateInRange(middleDate))
    }

    @MainActor
    func testCalendarDaysIncludeRange() throws {
        let date1 = Date(timeIntervalSince1970: 1735689600)
        let date2 = Date(timeIntervalSince1970: 1735862400)

        try viewModel.select(date1)
        try viewModel.select(date2)

        let calendarDays = viewModel.makeCalendarDays()
        let dateDays = calendarDays.filter { $0.date != nil }
        let rangeDays = dateDays.filter { $0.isInRange }

        XCTAssertFalse(rangeDays.isEmpty, "Should have days in range when 2 dates are selected")

        let selectedRangeDays = dateDays.filter { $0.isSelected && $0.isInRange }
        XCTAssertTrue(selectedRangeDays.isEmpty, "Selected dates should not be marked as in range")
    }

    @MainActor
    func testSingleDateNoRange() throws {
        let date = Date(timeIntervalSince1970: 1735689600)

        try viewModel.select(date)

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
    func testLoadNormalizesAndDeduplicatesDatesFromSameDay() {
        let morning = Date(timeIntervalSince1970: 1740787200)
        let afternoon = morning.addingTimeInterval(12 * 60 * 60)
        mockStorage.store(dates: [afternoon, morning])

        viewModel.load()

        XCTAssertEqual(viewModel.selectedDatesCount, 1)
        XCTAssertTrue(viewModel.isDateSelected(morning))
    }

    @MainActor
    func testLoadLimitsPersistedSelectionToTwoDates() {
        let firstDate = Date(timeIntervalSince1970: 1_740_787_200)
        let secondDate = firstDate.addingTimeInterval(86_400)
        let thirdDate = secondDate.addingTimeInterval(86_400)
        mockStorage.store(dates: [thirdDate, firstDate, secondDate])

        viewModel.load()

        XCTAssertEqual(viewModel.selectedDatesCount, 2)
        XCTAssertTrue(viewModel.isDateSelected(firstDate))
        XCTAssertTrue(viewModel.isDateSelected(secondDate))
        XCTAssertFalse(viewModel.isDateSelected(thirdDate))
    }

    @MainActor
    func testSelectAcceptsEpochWhenItIsToday() {
        let epoch = Date(timeIntervalSince1970: 0)
        let calendar = MockCalendarProvider(today: epoch)
        let model = CalendarViewModel(
            calendar: calendar,
            storage: MockDateStorage(),
            dateFormatter: mockDateFormatter
        )

        XCTAssertNoThrow(try model.select(epoch))

        XCTAssertEqual(model.selectedDatesCount, 1)
        XCTAssertTrue(model.isDateSelected(epoch))
    }

    @MainActor
    func testSelectionAndClearPersistThroughSingleStorageAPI() throws {
        let selectedDate = Date(timeIntervalSince1970: 1_735_776_000)

        try viewModel.select(selectedDate)
        XCTAssertEqual(try mockStorage.load(), [mockCalendar.startOfDay(for: selectedDate)])

        try viewModel.clear()
        XCTAssertEqual(try mockStorage.load(), [mockCalendar.today])
    }

    @MainActor
    func testSelectionRollsBackWhenStorageSaveFails() throws {
        viewModel.load()
        let originalDate = try XCTUnwrap(viewModel.firstSelectedDate)
        mockStorage.saveError = MockStorageError.expected

        XCTAssertThrowsError(try viewModel.select(originalDate.addingTimeInterval(86_400)))

        XCTAssertEqual(viewModel.selectedDatesCount, 1)
        XCTAssertTrue(viewModel.isDateSelected(originalDate))
        XCTAssertFalse(viewModel.isDateSelected(originalDate.addingTimeInterval(86_400)))
    }

    @MainActor
    func testClearRollsBackWhenStorageSaveFails() throws {
        viewModel.load()
        let originalDate = try XCTUnwrap(viewModel.firstSelectedDate)
        let secondDate = originalDate.addingTimeInterval(86_400)
        try viewModel.select(secondDate)
        mockStorage.saveError = MockStorageError.expected

        XCTAssertThrowsError(try viewModel.clear())

        XCTAssertEqual(viewModel.selectedDatesCount, 2)
        XCTAssertTrue(viewModel.isDateSelected(originalDate))
        XCTAssertTrue(viewModel.isDateSelected(secondDate))
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
    private let fixedToday: Date

    init(today: Date = Date(timeIntervalSince1970: 1735689600)) {
        fixedToday = today
    }

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_US_POSIX")
        cal.timeZone = .gmt
        return cal
    }

    var foundationCalendar: Calendar {
        calendar
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
        calendar.startOfDay(for: fixedToday)
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

    func isDateInWeekend(_ date: Date) -> Bool {
        calendar.isDateInWeekend(date)
    }
}

@MainActor
private class MockDateStorage: DateStorage {
    private var storedDates: [Date] = []
    var saveError: Error?

    func load() throws -> [Date] {
        storedDates
    }

    func store(dates: [Date]) {
        storedDates = dates
    }

    func save(_ dates: [Date]) throws {
        if let saveError {
            throw saveError
        }
        storedDates = dates
    }

}

private enum MockStorageError: Error {
    case expected
}

private class MockDateFormatterProvider: DateFormatterProvider {
    var locale: Locale? = Locale(identifier: "en_US_POSIX")
    var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()
    var dateFormat: String? = "MMMM yyyy"

    func string(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = dateFormat
        return formatter.string(from: date)
    }

    func string(from date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}
