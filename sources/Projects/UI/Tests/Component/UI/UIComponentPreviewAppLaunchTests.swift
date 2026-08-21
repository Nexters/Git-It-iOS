import XCTest

// MARK: - UIComponentPreviewAppLaunchTests

final class UIComponentPreviewAppLaunchTests: XCTestCase {
    func testCatalogIsReachableAfterLaunch() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()

        let catalog = app.descendants(matching: .any)["layout.contract.catalog"]
        XCTAssertTrue(
            catalog.waitForExistence(timeout: 5),
            "UIComponentPreviewApp 실행 후 layout.contract.catalog에 도달하지 못했습니다.",
        )
    }
}
