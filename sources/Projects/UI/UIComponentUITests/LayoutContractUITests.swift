import XCTest

final class LayoutContractUITests: XCTestCase {

    // MARK: Internal

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        let catalog = app.descendants(matching: .any)["layout.contract.catalog"]
        XCTAssertTrue(catalog.waitForExistence(timeout: 5))
    }

    func testLargeActionButtonStateDoesNotChangeHeight() {
        let primary = app.buttons["action.large.primary"]
        let disabled = app.buttons["action.large.disabled"]

        XCTAssertTrue(primary.waitForExistence(timeout: 2))
        XCTAssertTrue(disabled.waitForExistence(timeout: 2))
        assertDimension(primary.frame.height, equals: 54, contract: "action.large.height")
        assertDimension(disabled.frame.height, equals: 54, contract: "action.state.stable")
    }

    func testIconGlassButtonsMeetMinimumTouchTarget() {
        let medium = app.buttons["iconGlass.medium.neutral"]
        let small = app.buttons["iconGlass.small.neutral"]

        XCTAssertTrue(medium.waitForExistence(timeout: 2))
        XCTAssertTrue(small.waitForExistence(timeout: 2))
        assertMinimumTouchTarget(medium, contract: "iconGlass.medium.touch")
        assertMinimumTouchTarget(small, contract: "iconGlass.small.touch")
    }

    func testSmallActionButtonPreservesMinimumTouchTarget() {
        let small = app.buttons["action.small.primary"]

        XCTAssertTrue(small.waitForExistence(timeout: 2))
        assertDimension(small.frame.height, equals: 44, contract: "action.small.touch")
    }

    func testIconPlainButtonMeetsMinimumTouchTarget() {
        let button = app.buttons["iconPlain.default"]

        XCTAssertTrue(button.waitForExistence(timeout: 2))
        assertMinimumTouchTarget(button, contract: "iconPlain.touch")
    }

    // MARK: Private

    private var app = XCUIApplication()

    private func assertDimension(
        _ actual: CGFloat,
        equals expected: CGFloat,
        contract: String,
        tolerance: CGFloat = 0.5,
        file: StaticString = #filePath,
        line: UInt = #line,
    ) {
        XCTAssertEqual(
            actual,
            expected,
            accuracy: tolerance,
            "\(contract): expected \(expected)pt, actual \(actual)pt",
            file: file,
            line: line,
        )
    }

    private func assertMinimumTouchTarget(
        _ element: XCUIElement,
        contract: String,
        file: StaticString = #filePath,
        line: UInt = #line,
    ) {
        let frame = element.frame
        XCTAssertGreaterThanOrEqual(
            frame.width,
            44,
            "\(contract): expected width >= 44pt, actual \(frame.width)pt",
            file: file,
            line: line,
        )
        XCTAssertGreaterThanOrEqual(
            frame.height,
            44,
            "\(contract): expected height >= 44pt, actual \(frame.height)pt",
            file: file,
            line: line,
        )
    }

}
