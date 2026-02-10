 import XCTest
@testable import CalendarView

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
}
