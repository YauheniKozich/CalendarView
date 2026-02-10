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
    }

    @MainActor
    func testExplosionAfterFiveTaps() throws {
        let app = XCUIApplication()
        app.launch()

        let collectionView = app.collectionViews["calendarCollectionView"]
        XCTAssertTrue(collectionView.waitForExistence(timeout: 5))

        let cells = collectionView.cells
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

        let cell = try XCTUnwrap(targetCell, "No hittable calendar cell found")

        for _ in 0..<5 {
            cell.tap()
        }

        let notHittable = NSPredicate(format: "isHittable == false")
        expectation(for: notHittable, evaluatedWith: cell)
        waitForExpectations(timeout: 5)
    }

}
