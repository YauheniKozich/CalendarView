 import XCTest

final class CalendarViewTestsUI: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    @MainActor
    func testExample() throws {
        let app = XCUIApplication()
        app.launch()

        let weekdayLabels = app.staticTexts.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "calendarWeekday_")
        )
        XCTAssertEqual(weekdayLabels.count, 7)
    }

    @MainActor
    func testExplosionAfterFiveTaps() throws {
        let app = XCUIApplication()
        app.launch()

        let collectionView = app.collectionViews["calendarCollectionView"]
        XCTAssertTrue(collectionView.waitForExistence(timeout: 5))

        let cells = collectionView.cells.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "calendarCell_")
        )
        var targetCell: XCUIElement?
        let maxIndex = min(cells.count, 42)
        if maxIndex > 0 {
            for index in 0..<maxIndex {
                let candidate = cells.element(boundBy: index)
                if candidate.exists && candidate.isHittable {
                    targetCell = candidate
                    break
                }
            }
        }

        let target = try XCTUnwrap(targetCell, "No hittable date cell found")
        // Collection indices can change when selection updates or cells move.
        let cell = collectionView.cells[target.identifier]
        let originalFrame = cell.frame
        let isInOriginalPosition = NSPredicate { _, _ in
            guard cell.exists else { return false }
            let frame = cell.frame
            return abs(frame.midX - originalFrame.midX) < 2
                && abs(frame.midY - originalFrame.midY) < 2
                && abs(frame.width - originalFrame.width) < 2
                && abs(frame.height - originalFrame.height) < 2
        }

        for _ in 0..<5 {
            cell.tap()
        }

        // A displaced cell can still be hittable; verify that it left the grid.
        let displaced = NSCompoundPredicate(notPredicateWithSubpredicate: isInOriginalPosition)
        expectation(for: displaced, evaluatedWith: cell)
        waitForExpectations(timeout: 5)

        let autoRestored = XCTNSPredicateExpectation(
            predicate: isInOriginalPosition,
            object: cell
        )
        autoRestored.isInverted = true
        wait(for: [autoRestored], timeout: 11)
        XCTAssertFalse(isInOriginalPosition.evaluate(with: cell), "Animation completion should not restore the grid")

        let restoreButton = app.buttons["calendarRestoreButton"]
        XCTAssertTrue(restoreButton.exists)
        restoreButton.tap()

        expectation(for: isInOriginalPosition, evaluatedWith: cell)
        waitForExpectations(timeout: 5)
        XCTAssertTrue(cell.isHittable, "Calendar cells should return to the grid after restore")
    }

}
