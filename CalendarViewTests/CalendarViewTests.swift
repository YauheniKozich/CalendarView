 import XCTest
import UIKit
@testable import CalendarView

@MainActor
final class CalendarViewTests: XCTestCase {
    func testTapTrackerThreshold() {
        let tracker = TapTracker(tapThreshold: 5)
        for _ in 0..<4 {
            XCTAssertFalse(tracker.registerTap())
        }
        XCTAssertTrue(tracker.registerTap())

        tracker.resetTapCount()
        XCTAssertFalse(tracker.registerTap())
    }

    func testLocalizedCalendarUsesLocaleWeekStartAndSymbols() {
        let usCalendar = DependencyFactories.CalendarProviderFactory.make(
            for: Locale(identifier: "en_US")
        )
        let ukCalendar = DependencyFactories.CalendarProviderFactory.make(
            for: Locale(identifier: "en_GB")
        )

        XCTAssertEqual(usCalendar.firstWeekday, 1)
        XCTAssertEqual(ukCalendar.firstWeekday, 2)
        XCTAssertEqual(ukCalendar.shortWeekdaySymbols.count, 7)
    }

    func testCalendarProviderPreservesInjectedTimeZone() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Pacific/Honolulu"))
        let provider = CalendarProviderImpl(calendar: calendar)
        let date = Date(timeIntervalSince1970: 1_735_693_200)

        XCTAssertEqual(provider.component(.day, from: date), 31)
    }

    func testDateFormatterUsesConfiguredCalendar() throws {
        var calendar = Calendar(identifier: .buddhist)
        calendar.timeZone = .gmt
        // Keep the fixture away from the year boundary in every system time zone.
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2568, month: 6, day: 15)))
        let formatter = DateFormatterProviderImpl(
            locale: Locale(identifier: "en_US"),
            calendar: calendar,
            dateFormat: "yyyy"
        )

        XCTAssertEqual(formatter.string(from: date), "2568")
    }

    func testCalendarDayPlaceholderEqualityIsReflexive() {
        let provider = CalendarProviderImpl(calendar: Calendar(identifier: .gregorian))
        let placeholder = CalendarDay(
            date: nil,
            selectedDatesSet: [],
            range: nil,
            calendar: provider
        )

        XCTAssertEqual(placeholder, placeholder)
        XCTAssertEqual(Set([placeholder, placeholder]).count, 1)
    }

    func testCalendarStringsFollowConfiguredLocale() {
        XCTAssertEqual(
            CalendarStrings.localized(.clearDates, locale: Locale(identifier: "ru_RU")),
            "Очистить даты"
        )
        XCTAssertEqual(
            CalendarStrings.localized(.clearDates, locale: Locale(identifier: "en_US")),
            "Clear dates"
        )
    }

    func testUserDefaultsDateStorageRoundTrips() throws {
        let suiteName = "CalendarViewTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        let storage = UserDefaultsDateStorage(key: "dates", defaults: defaults)
        let syncDates = [Date(timeIntervalSince1970: 0), Date(timeIntervalSince1970: 1_735_689_600)]
        defer { defaults.removePersistentDomain(forName: suiteName) }

        try storage.save(syncDates)
        XCTAssertEqual(try storage.load(), syncDates)
    }

    func testRestorePreservesDisabledCellInteractionState() {
        let animator = CalendarExplosionAnimator(tapThreshold: 1)
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 640))
        let cell = UICollectionViewCell(frame: CGRect(x: 20, y: 20, width: 40, height: 40))
        cell.isUserInteractionEnabled = false
        container.addSubview(cell)

        animator.registerTap(on: [cell], in: container)
        XCTAssertFalse(cell.isUserInteractionEnabled)

        animator.restoreUserInteraction(items: [cell], in: container)

        XCTAssertFalse(cell.isUserInteractionEnabled)
    }

    func testCancellingAsyncExplosionRestoresAnimatorForNextRun() async {
        let animator = CalendarExplosionAnimator(animationTimeout: 60)
        defer { animator.reset() }
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 640))
        let cell = UICollectionViewCell(frame: CGRect(x: 20, y: 20, width: 40, height: 40))
        container.addSubview(cell)

        let firstRun = Task { @MainActor in
            await animator.explodeAsync(items: [cell], in: container)
        }
        for _ in 0..<100 where !animator.isAnimating {
            await Task.yield()
        }
        XCTAssertTrue(animator.isAnimating)

        firstRun.cancel()
        let firstRunResult = await firstRun.value
        XCTAssertFalse(firstRunResult)
        XCTAssertFalse(animator.isAnimating)

        let secondRun = Task { @MainActor in
            await animator.explodeAsync(items: [cell], in: container)
        }
        await Task.yield()
        XCTAssertTrue(animator.isAnimating)

        secondRun.cancel()
        _ = await secondRun.value
    }
}
