import XCTest

final class ComponentPreviewCatalogUITests: XCTestCase {
    func testAllPublicComponentRoutesAndEnvironmentFixturesAreReachable() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.otherElements["component.preview.catalog"].waitForExistence(timeout: 5))

        let componentIDs = [
            "action-button",
            "continuous-progress-bar",
            "icon-glass-button",
            "icon-plain-button",
            "progress-segments",
            "resource-animation",
            "resource-image",
            "screen-edge-scrim",
            "styled-text",
            "tag-badge",
            "action-menu",
            "bottom-action-bar",
            "empty-state",
            "home-project-card",
            "onboarding-mockup",
            "project-row",
            "saved-question-card",
            "screen-container",
            "screen-header",
            "selection-card",
            "selection-card-list",
            "sheet-surface",
            "tab-shell",
        ]

        for componentID in componentIDs {
            XCTAssertTrue(
                app.descendants(matching: .any)["component.preview.route.\(componentID)"].exists,
                "Preview route missing: \(componentID)",
            )
        }
    }

    func testAppearanceDynamicTypeReduceMotionAndFallbackFixturesRemainObservable() {
        let app = XCUIApplication()
        app.launchArguments = ["--preview-dark", "--maximum-dynamic-type", "--reduce-motion", "--resource-fallback"]
        app.launch()

        XCTAssertTrue(app.otherElements["component.preview.catalog"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["component.preview.environment.appearance.dark"].exists)
        XCTAssertTrue(app.staticTexts["component.preview.environment.dynamicType.maximum"].exists)
        XCTAssertTrue(app.staticTexts["component.preview.environment.reduceMotion.enabled"].exists)
        XCTAssertTrue(app.staticTexts["component.preview.environment.fallback.enabled"].exists)
    }
}
