import CoreGraphics
import UIKit
import XCTest

// MARK: - LayoutContractUITests

final class LayoutContractUITests: XCTestCase {

    // MARK: Internal

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        launchCatalog()
    }

    func testLargeActionButtonStateDoesNotChangeHeight() {
        let primary = element(identifier: "action.large.primary")
        let disabled = element(identifier: "action.large.disabled")

        assertExists(primary, contract: "action.large.height")
        assertExists(disabled, contract: "action.state.stable")
        assertDimension(primary.frame.height, equals: 54, contract: "action.large.height")
        assertDimension(disabled.frame.height, equals: 54, contract: "action.state.stable")
    }

    func testActionButtonSurfaceTiersPreserveMinimumHitArea() throws {
        let contracts: [(identifier: String, surfaceHeight: CGFloat, contract: String)] = [
            ("action.large.primary", 54, "action.large.surface"),
            ("action.medium.primary", 40, "action.medium.surface"),
            ("action.small.primary", 36, "action.small.surface"),
        ]

        for contract in contracts {
            let button = reveal(identifier: contract.identifier)
            assertMinimumTouchTarget(button, contract: "\(contract.contract).touch")

            let surfaceBounds = try renderedBounds(
                of: button,
                matching: .blue100,
                contract: contract.contract,
            )
            assertDimension(
                surfaceBounds.height,
                equals: contract.surfaceHeight,
                contract: contract.contract,
            )
        }
    }

    func testIconGlassButtonsMeetMinimumTouchTarget() {
        let medium = reveal(identifier: "iconGlass.medium.neutral")
        let small = reveal(identifier: "iconGlass.small.neutral")

        assertMinimumTouchTarget(medium, contract: "iconGlass.medium.touch")
        assertMinimumTouchTarget(small, contract: "iconGlass.small.touch")
    }

    func testSmallActionButtonPreservesMinimumTouchTarget() {
        let small = reveal(identifier: "action.small.primary")

        assertDimension(small.frame.height, equals: 44, contract: "action.small.touch")
    }

    func testIconPlainButtonMeetsMinimumTouchTarget() {
        let button = reveal(identifier: "iconPlain.default")

        assertMinimumTouchTarget(button, contract: "iconPlain.touch")
    }

    func testSheetSurfaceGrabberAndAreaMatchContract() throws {
        let surface = reveal(identifier: "sheet.surface")
        let backgroundBounds = try renderedBounds(
            of: surface,
            matching: .grey600,
            contract: "sheet.surface.background",
        )
        let grabberBounds = try renderedBounds(
            of: surface,
            matching: .grey400,
            contract: "sheet.grabber",
            recoverHorizontalCapsuleEdges: true,
        )
        let contentBounds = try renderedBounds(
            of: surface,
            matching: .purple300,
            contract: "sheet.grabberArea",
        )

        assertDimension(grabberBounds.width, equals: 58, contract: "sheet.grabber.width")
        assertDimension(grabberBounds.height, equals: 4, contract: "sheet.grabber.height")
        assertDimension(
            grabberBounds.minY - backgroundBounds.minY,
            equals: 5,
            contract: "sheet.grabber.top",
        )
        assertDimension(
            contentBounds.minY - backgroundBounds.minY,
            equals: 16,
            contract: "sheet.grabberArea",
        )
    }

    func testProjectRowsMatchStateHeightAndDirectionalInsets() throws {
        let defaultRow = reveal(identifier: "project.row.default")
        let defaultThumbnailBounds = try renderedBounds(
            of: defaultRow,
            matching: .purple300,
            contract: "projectRow.thumbnail.default",
        )
        let defaultLowerComponents = try renderedComponentBounds(
            of: defaultRow,
            matching: .grey500,
            contract: "projectRow.lowerContent.default",
        )
        let largestLowerComponents = Array(defaultLowerComponents.prefix(2))
        let progressTrackBounds = try XCTUnwrap(
            largestLowerComponents.max(by: { $0.width < $1.width }),
            diagnostic(
                contract: "projectRow.progressTrack",
                expected: "wide progress track geometry marker",
                actual: "components=\(largestLowerComponents)",
            ),
        )
        let tagBounds = try XCTUnwrap(
            largestLowerComponents.max(by: { $0.height < $1.height }),
            diagnostic(
                contract: "projectRow.tag",
                expected: "tall tag geometry marker",
                actual: "components=\(largestLowerComponents)",
            ),
        )

        assertDimension(defaultRow.frame.width, equals: 320, contract: "projectRow.width")
        assertMinimumDimension(
            defaultRow.frame.height,
            atLeast: 150,
            contract: "projectRow.defaultHeight",
        )
        assertDimension(defaultThumbnailBounds.width, equals: 60, contract: "projectRow.thumbnail.width")
        assertDimension(defaultThumbnailBounds.height, equals: 60, contract: "projectRow.thumbnail.height")
        assertDimension(defaultThumbnailBounds.minX, equals: 18, contract: "projectRow.insets.horizontal")
        assertDimension(defaultThumbnailBounds.minY, equals: 16, contract: "projectRow.insets.top")
        assertDimension(progressTrackBounds.height, equals: 6, contract: "projectRow.progressTrack.height")
        assertDimension(
            defaultRow.frame.width - progressTrackBounds.maxX,
            equals: 18,
            contract: "projectRow.insets.horizontal",
        )
        assertDimension(
            progressTrackBounds.minY - defaultThumbnailBounds.maxY,
            equals: 12,
            contract: "projectRow.spacing.thumbnailToProgress",
        )
        assertDimension(
            tagBounds.minY - progressTrackBounds.maxY,
            equals: 12,
            contract: "projectRow.spacing.progressToTag",
        )
        assertDimension(
            defaultRow.frame.height - tagBounds.maxY,
            equals: 18,
            contract: "projectRow.insets.bottom",
        )

        let deleteRow = reveal(identifier: "project.row.delete")
        let deleteThumbnailBounds = try renderedBounds(
            of: deleteRow,
            matching: .purple300,
            contract: "projectRow.thumbnail.delete",
        )

        assertDimension(deleteRow.frame.width, equals: 320, contract: "projectRow.width")
        assertDimension(deleteRow.frame.height, equals: 94, contract: "projectRow.deleteHeight")
        assertDimension(deleteThumbnailBounds.minX, equals: 18, contract: "projectRow.insets.horizontal")
        assertDimension(deleteThumbnailBounds.minY, equals: 16, contract: "projectRow.insets.top")
        assertDimension(
            deleteRow.frame.height - deleteThumbnailBounds.maxY,
            equals: 18,
            contract: "projectRow.insets.bottom",
        )
    }

    func testTagBadgePreservesEightPointCornerRadius() throws {
        let badge = reveal(identifier: "tag.accent")
        let image = try renderedImage(of: badge, contract: "tag.radius")
        let radius = try XCTUnwrap(
            image.estimatedTopLeftCornerRadius(
                matching: .blue100,
                pointSize: badge.frame.size,
            ),
            diagnostic(
                contract: "tag.radius",
                expected: "8pt rounded corner samples",
                actual: "no matching samples",
            ),
        )

        assertDimension(
            radius,
            equals: 8,
            contract: "tag.radius",
            tolerance: 1,
        )
    }

    func testNewComponentScenarioFramesMatchContracts() {
        let progress = reveal(identifier: "progress.continuous")
        assertDimension(progress.frame.width, equals: 320, contract: "progress.width")
        assertDimension(progress.frame.height, equals: 6, contract: "progress.height")

        let menu = reveal(identifier: "action.menu")
        assertDimension(menu.frame.width, equals: 181, contract: "project.menu.width")
        assertDimension(menu.frame.height, equals: 126, contract: "project.menu.height")

        let topScrim = reveal(identifier: "scrim.top")
        assertDimension(topScrim.frame.height, equals: 103, contract: "project.edge.top")

        let bottomScrim = reveal(identifier: "scrim.bottom")
        assertDimension(bottomScrim.frame.height, equals: 127, contract: "project.edge.bottom")
    }

    func testContinuousProgressBarStatesRenderFillAndAccessibility() throws {
        let contracts: [(identifier: String, fillWidth: CGFloat, value: String)] = [
            ("progress.zero", 0, "0퍼센트"),
            ("progress.continuous", 208, "65퍼센트"),
            ("progress.complete", 320, "100퍼센트"),
        ]

        for contract in contracts {
            let progress = reveal(identifier: contract.identifier)
            let fillWidth = try renderedWidth(
                of: progress,
                matching: .blue200,
                contract: "\(contract.identifier).fill",
                recoverHorizontalCapsuleEdges: contract.fillWidth > 0,
            )

            assertDimension(
                fillWidth,
                equals: contract.fillWidth,
                contract: "\(contract.identifier).fill",
            )
            XCTAssertEqual(
                progress.label,
                "학습 진행률",
                diagnostic(
                    contract: "\(contract.identifier).label",
                    expected: "학습 진행률",
                    actual: progress.label,
                ),
            )
            assertAccessibilityValue(
                of: progress,
                equals: contract.value,
                contract: "\(contract.identifier).value",
            )
        }
    }

    func test_메뉴_버튼은_겹치지_않고_선택을_전달한다() {
        let menu = reveal(identifier: "action.menu")
        let deleteButton = app.buttons["학습 프로젝트 삭제 모드 열기"]
        let closeButton = app.buttons["프로젝트 메뉴 닫기"]
        let selection = element(identifier: "action.menu.selection")

        assertExists(deleteButton, contract: "action.menu.delete.button")
        assertExists(closeButton, contract: "action.menu.close.button")
        assertExists(selection, contract: "action.menu.selection")
        assertButtonTrait(deleteButton, contract: "action.menu.delete.trait")
        assertButtonTrait(closeButton, contract: "action.menu.close.trait")
        assertNonOverlapping(
            upper: deleteButton,
            lower: closeButton,
            contract: "action.menu.items.nonOverlap",
        )
        assertDimension(
            deleteButton.frame.minY - menu.frame.minY,
            equals: 8,
            contract: "action.menu.insets.top",
        )
        assertDimension(
            deleteButton.frame.minX - menu.frame.minX,
            equals: 14,
            contract: "action.menu.insets.leading",
        )
        assertDimension(
            menu.frame.maxX - deleteButton.frame.maxX,
            equals: 14,
            contract: "action.menu.insets.trailing",
        )
        assertDimension(
            menu.frame.maxY - closeButton.frame.maxY,
            equals: 9,
            contract: "action.menu.insets.bottom",
        )

        deleteButton.tap()
        assertAccessibilityValue(
            of: selection,
            equals: "delete",
            contract: "action.menu.selection.delete",
        )

        closeButton.tap()
        assertAccessibilityValue(
            of: selection,
            equals: "close",
            contract: "action.menu.selection.close",
        )
    }

    func testScreenEdgeScrimsAllowUnderlyingButtonTaps() {
        let contracts = [
            (button: "scrim.top", marker: "scrim.top.tap.count", contract: "project.edge.top.hitTesting"),
            (button: "scrim.bottom", marker: "scrim.bottom.tap.count", contract: "project.edge.bottom.hitTesting"),
        ]

        for contract in contracts {
            let button = reveal(identifier: contract.button)
            let marker = element(identifier: contract.marker)

            assertExists(marker, contract: "\(contract.contract).marker")
            assertButtonTrait(button, contract: "\(contract.contract).button")
            assertAccessibilityValue(of: marker, equals: "0", contract: "\(contract.contract).initial")

            button.tap()
            assertAccessibilityValue(of: marker, equals: "1", contract: contract.contract)
        }
    }

    func testMaximumDynamicTypeKeepsProjectRowContentReadable() {
        app.terminate()
        app = XCUIApplication()
        app.launchArguments = ["--maximum-dynamic-type"]
        launchCatalog()

        let defaultRow = reveal(identifier: "project.row.default")
        let deleteRow = element(identifier: "project.row.delete")
        let defaultFrame = defaultRow.frame
        let deleteFrame = deleteRow.frame

        XCTAssertGreaterThanOrEqual(
            defaultFrame.height,
            150,
            diagnostic(
                contract: "projectRow.maximumDynamicType.minimumHeight",
                expected: ">= 150pt",
                actual: "\(defaultFrame.height)pt",
            ),
        )
        XCTAssertLessThanOrEqual(
            defaultFrame.maxY,
            deleteFrame.minY,
            diagnostic(
                contract: "projectRow.maximumDynamicType.nonOverlap",
                expected: "default maxY <= delete minY",
                actual: "\(defaultFrame.maxY) > \(deleteFrame.minY)",
            ),
        )
        XCTAssertTrue(
            defaultRow.label.contains("Git It iOS 접근성 레이아웃 검증")
                && defaultRow.label.contains("Presentation 구조와 상태 흐름"),
            diagnostic(
                contract: "projectRow.maximumDynamicType.fullAccessibilityText",
                expected: "full name and set title",
                actual: defaultRow.label,
            ),
        )

        let visibleFrame = app.frame.intersection(defaultFrame)
        assertDimension(
            visibleFrame.height,
            equals: defaultFrame.height,
            contract: "projectRow.maximumDynamicType.notClipped",
        )
    }

    func testMaximumDynamicTypeKeepsActionMenuButtonsNonOverlapping() {
        app.terminate()
        app = XCUIApplication()
        app.launchArguments = ["--maximum-dynamic-type"]
        launchCatalog()

        let menu = reveal(identifier: "action.menu")
        let deleteButton = app.buttons["학습 프로젝트 삭제 모드 열기"]
        let closeButton = app.buttons["프로젝트 메뉴 닫기"]

        assertExists(deleteButton, contract: "action.menu.maximumDynamicType.delete")
        assertExists(closeButton, contract: "action.menu.maximumDynamicType.close")
        XCTAssertGreaterThanOrEqual(
            menu.frame.height,
            126,
            diagnostic(
                contract: "action.menu.maximumDynamicType.minimumHeight",
                expected: ">= 126pt",
                actual: "\(menu.frame.height)pt",
            ),
        )
        assertNonOverlapping(
            upper: deleteButton,
            lower: closeButton,
            contract: "action.menu.maximumDynamicType.nonOverlap",
        )
    }

    func testPolicyAgreementRowCombinesTitleAndRequirementIntoSingleAccessibilityElement() {
        let unselected = reveal(identifier: "policyAgreementRow.unselected")

        XCTAssertTrue(
            unselected.label.hasPrefix("필수, 서비스 이용 약관"),
            diagnostic(
                contract: "policyAgreementRow.unselected.label",
                expected: "label starting with \"필수, 서비스 이용 약관\"",
                actual: unselected.label,
            ),
        )
    }

    func testPolicyAgreementRowExposesIsSelectedTraitSeparatelyFromColor() {
        let selected = reveal(identifier: "policyAgreementRow.selected")
        let unselected = reveal(identifier: "policyAgreementRow.unselected")

        XCTAssertTrue(
            selected.isSelected,
            diagnostic(
                contract: "policyAgreementRow.selected.isSelected",
                expected: "isSelected=true",
                actual: "isSelected=\(selected.isSelected)",
            ),
        )
        XCTAssertFalse(
            unselected.isSelected,
            diagnostic(
                contract: "policyAgreementRow.unselected.isSelected",
                expected: "isSelected=false",
                actual: "isSelected=\(unselected.isSelected)",
            ),
        )
    }

    func testPolicyAgreementRowOpenLinkButtonHasOwnAccessibilityLabel() {
        _ = reveal(identifier: "policyAgreementRow.unselected")
        let openLinkButton = app.buttons["서비스 이용 약관 전문 보기"]

        assertExists(openLinkButton, contract: "policyAgreementRow.unselected.openLink")
        assertButtonTrait(openLinkButton, contract: "policyAgreementRow.unselected.openLink.trait")
    }

    func testContractDiagnosticContainsIdentifierExpectedAndActual() {
        let message = diagnostic(
            contract: "diagnostic.contract",
            expected: "44pt",
            actual: "40pt",
        )

        XCTAssertTrue(message.contains("diagnostic.contract"))
        XCTAssertTrue(message.contains("expected 44pt"))
        XCTAssertTrue(message.contains("actual 40pt"))
    }

    // MARK: Private

    private var app = XCUIApplication()

    private func launchCatalog() {
        app.launch()
        let catalog = element(identifier: "layout.contract.catalog")
        XCTAssertTrue(
            catalog.waitForExistence(timeout: 5),
            diagnostic(
                contract: "catalog.launch",
                expected: "layout.contract.catalog exists",
                actual: "exists=\(catalog.exists)",
            ),
        )
    }

    private func element(identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    @discardableResult
    private func reveal(
        identifier: String,
        file: StaticString = #filePath,
        line: UInt = #line,
    ) -> XCUIElement {
        let element = element(identifier: identifier)
        if !element.waitForExistence(timeout: 0.5) {
            for _ in 0..<12 {
                app.swipeUp()
                if element.waitForExistence(timeout: 0.25) {
                    break
                }
            }
        }
        assertExists(element, contract: "\(identifier).exists", file: file, line: line)

        let viewport = app.frame.insetBy(dx: 1, dy: 1)
        for _ in 0..<12 where !viewport.contains(element.frame) {
            if element.frame.maxY > viewport.maxY {
                app.swipeUp()
            } else {
                app.swipeDown()
            }
        }

        XCTAssertTrue(
            viewport.contains(element.frame),
            diagnostic(
                contract: "\(identifier).visible",
                expected: "frame inside \(viewport)",
                actual: "frame=\(element.frame)",
            ),
            file: file,
            line: line,
        )
        return element
    }

    private func assertExists(
        _ element: XCUIElement,
        contract: String,
        file: StaticString = #filePath,
        line: UInt = #line,
    ) {
        XCTAssertTrue(
            element.waitForExistence(timeout: 2),
            diagnostic(
                contract: contract,
                expected: "element exists",
                actual: "exists=\(element.exists)",
            ),
            file: file,
            line: line,
        )
    }

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
            diagnostic(
                contract: contract,
                expected: "\(expected)pt",
                actual: "\(actual)pt",
            ),
            file: file,
            line: line,
        )
    }

    private func assertMinimumDimension(
        _ actual: CGFloat,
        atLeast expected: CGFloat,
        contract: String,
        file: StaticString = #filePath,
        line: UInt = #line,
    ) {
        XCTAssertGreaterThanOrEqual(
            actual,
            expected,
            diagnostic(
                contract: contract,
                expected: ">= \(expected)pt",
                actual: "\(actual)pt",
            ),
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
            frame.width + 0.001,
            44,
            diagnostic(
                contract: "\(contract).width",
                expected: ">= 44pt",
                actual: "\(frame.width)pt",
            ),
            file: file,
            line: line,
        )
        XCTAssertGreaterThanOrEqual(
            frame.height + 0.001,
            44,
            diagnostic(
                contract: "\(contract).height",
                expected: ">= 44pt",
                actual: "\(frame.height)pt",
            ),
            file: file,
            line: line,
        )
    }

    private func assertAccessibilityValue(
        of element: XCUIElement,
        equals expected: String,
        contract: String,
        file: StaticString = #filePath,
        line: UInt = #line,
    ) {
        let actual = element.value as? String ?? String(describing: element.value)
        XCTAssertEqual(
            actual,
            expected,
            diagnostic(contract: contract, expected: expected, actual: actual),
            file: file,
            line: line,
        )
    }

    private func assertButtonTrait(
        _ element: XCUIElement,
        contract: String,
        file: StaticString = #filePath,
        line: UInt = #line,
    ) {
        XCTAssertEqual(
            element.elementType,
            .button,
            diagnostic(
                contract: contract,
                expected: "button",
                actual: String(describing: element.elementType),
            ),
            file: file,
            line: line,
        )
    }

    private func assertNonOverlapping(
        upper: XCUIElement,
        lower: XCUIElement,
        contract: String,
        accessibilityFrameTolerance: CGFloat = 8,
        file: StaticString = #filePath,
        line: UInt = #line,
    ) {
        let upperFrame = upper.frame
        let lowerFrame = lower.frame

        XCTAssertLessThanOrEqual(
            upperFrame.maxY,
            lowerFrame.minY + accessibilityFrameTolerance,
            diagnostic(
                contract: contract,
                expected: "upper maxY <= lower minY + \(accessibilityFrameTolerance)pt accessibility frame tolerance",
                actual: "upper maxY=\(upperFrame.maxY), lower minY=\(lowerFrame.minY)",
            ),
            file: file,
            line: line,
        )
    }

    private func renderedBounds(
        of element: XCUIElement,
        matching color: GeometryMarkerColor,
        contract: String,
        largestComponentCount: Int = 1,
        recoverHorizontalCapsuleEdges: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line,
    ) throws -> CGRect {
        let image = try renderedImage(of: element, contract: contract, file: file, line: line)
        let pixelBounds = try XCTUnwrap(
            image.bounds(matching: color, largestComponentCount: largestComponentCount),
            diagnostic(
                contract: contract,
                expected: "matching rendered pixels",
                actual: "none in \(image.width)x\(image.height) image",
            ),
            file: file,
            line: line,
        )
        let measuredBounds = recoverHorizontalCapsuleEdges
            ? pixelBounds
                .insetBy(dx: -1, dy: 0)
                .intersection(
                    CGRect(x: 0, y: 0, width: CGFloat(image.width), height: CGFloat(image.height))
                )
            : pixelBounds
        return image.pointBounds(for: measuredBounds, pointSize: element.frame.size)
    }

    private func renderedComponentBounds(
        of element: XCUIElement,
        matching color: GeometryMarkerColor,
        contract: String,
        file: StaticString = #filePath,
        line: UInt = #line,
    ) throws -> [CGRect] {
        let image = try renderedImage(of: element, contract: contract, file: file, line: line)
        let pixelBounds = image.componentBounds(matching: color)
        _ = try XCTUnwrap(
            pixelBounds.first,
            diagnostic(
                contract: contract,
                expected: "connected geometry marker pixels",
                actual: "none in \(image.width)x\(image.height) image",
            ),
            file: file,
            line: line,
        )
        return pixelBounds.map { bounds in
            image.pointBounds(for: bounds, pointSize: element.frame.size)
        }
    }

    private func renderedWidth(
        of element: XCUIElement,
        matching color: GeometryMarkerColor,
        contract: String,
        recoverHorizontalCapsuleEdges: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line,
    ) throws -> CGFloat {
        let image = try renderedImage(of: element, contract: contract, file: file, line: line)
        guard let pixelBounds = image.bounds(matching: color) else { return 0 }
        let measuredBounds = recoverHorizontalCapsuleEdges
            ? pixelBounds
                .insetBy(dx: -1, dy: 0)
                .intersection(
                    CGRect(x: 0, y: 0, width: CGFloat(image.width), height: CGFloat(image.height))
                )
            : pixelBounds
        return image.pointBounds(for: measuredBounds, pointSize: element.frame.size).width
    }

    private func renderedImage(
        of element: XCUIElement,
        contract: String,
        file: StaticString = #filePath,
        line: UInt = #line,
    ) throws -> PixelImage {
        let screenshot = app.screenshot().image
        let sourceImage = try XCTUnwrap(
            uprightCGImage(from: screenshot),
            diagnostic(
                contract: contract,
                expected: "upright app screenshot CGImage",
                actual: "image conversion failed",
            ),
            file: file,
            line: line,
        )
        let cropRect = try XCTUnwrap(
            pixelCropRect(
                elementFrame: element.frame,
                appFrame: app.frame,
                pixelWidth: sourceImage.width,
                pixelHeight: sourceImage.height,
            ),
            diagnostic(
                contract: contract,
                expected: "non-empty element crop inside app frame",
                actual: "element=\(element.frame), app=\(app.frame)",
            ),
            file: file,
            line: line,
        )
        let croppedImage = try XCTUnwrap(
            sourceImage.cropping(to: cropRect),
            diagnostic(
                contract: contract,
                expected: "cropped element CGImage",
                actual: "crop=\(cropRect), source=\(sourceImage.width)x\(sourceImage.height)",
            ),
            file: file,
            line: line,
        )

        return try XCTUnwrap(
            PixelImage(cgImage: croppedImage),
            diagnostic(
                contract: contract,
                expected: "renderable RGBA image",
                actual: "image conversion failed",
            ),
            file: file,
            line: line,
        )
    }

    private func uprightCGImage(from image: UIImage) -> CGImage? {
        guard image.imageOrientation != .up else { return image.cgImage }

        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }.cgImage
    }

    private func pixelCropRect(
        elementFrame: CGRect,
        appFrame: CGRect,
        pixelWidth: Int,
        pixelHeight: Int,
    ) -> CGRect? {
        guard
            appFrame.width > 0,
            appFrame.height > 0,
            pixelWidth > 0,
            pixelHeight > 0
        else { return nil }

        let visibleFrame = elementFrame.intersection(appFrame)
        guard !visibleFrame.isNull, !visibleFrame.isEmpty else { return nil }

        let horizontalScale = CGFloat(pixelWidth) / appFrame.width
        let verticalScale = CGFloat(pixelHeight) / appFrame.height
        let minimumX = floor((visibleFrame.minX - appFrame.minX) * horizontalScale)
        let minimumY = floor((visibleFrame.minY - appFrame.minY) * verticalScale)
        let maximumX = ceil((visibleFrame.maxX - appFrame.minX) * horizontalScale)
        let maximumY = ceil((visibleFrame.maxY - appFrame.minY) * verticalScale)
        let clampedMinimumX = max(0, min(CGFloat(pixelWidth), minimumX))
        let clampedMinimumY = max(0, min(CGFloat(pixelHeight), minimumY))
        let clampedMaximumX = max(0, min(CGFloat(pixelWidth), maximumX))
        let clampedMaximumY = max(0, min(CGFloat(pixelHeight), maximumY))

        guard
            clampedMaximumX > clampedMinimumX,
            clampedMaximumY > clampedMinimumY
        else { return nil }

        return CGRect(
            x: clampedMinimumX,
            y: clampedMinimumY,
            width: clampedMaximumX - clampedMinimumX,
            height: clampedMaximumY - clampedMinimumY,
        )
    }

    private func diagnostic(
        contract: String,
        expected: String,
        actual: String,
    ) -> String {
        "\(contract): expected \(expected), actual \(actual)"
    }

}

// MARK: - GeometryMarkerColor

private struct GeometryMarkerColor {

    // MARK: Internal

    static let blue100 = GeometryMarkerColor(red: 185, green: 214, blue: 254)
    static let blue200 = GeometryMarkerColor(red: 139, green: 181, blue: 239)
    static let purple300 = GeometryMarkerColor(red: 137, green: 141, blue: 166)
    static let grey600 = GeometryMarkerColor(red: 36, green: 36, blue: 37)
    static let grey500 = GeometryMarkerColor(red: 59, green: 59, blue: 59)
    static let grey400 = GeometryMarkerColor(red: 145, green: 145, blue: 145)

    let red: UInt8
    let green: UInt8
    let blue: UInt8

    func matches(
        red actualRed: UInt8,
        green actualGreen: UInt8,
        blue actualBlue: UInt8,
    ) -> Bool {
        abs(Int(red) - Int(actualRed)) <= Int(Self.rasterizationChannelTolerance)
            && abs(Int(green) - Int(actualGreen)) <= Int(Self.rasterizationChannelTolerance)
            && abs(Int(blue) - Int(actualBlue)) <= Int(Self.rasterizationChannelTolerance)
    }

    // MARK: Private

    private static let rasterizationChannelTolerance: UInt8 = 6

}

// MARK: - PixelImage

private struct PixelImage {

    // MARK: Lifecycle

    init?(cgImage: CGImage) {
        let width = cgImage.width
        let height = cgImage.height
        var storage = [UInt8](repeating: 0, count: width * height * Constant.bytesPerPixel)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue
            | CGImageAlphaInfo.premultipliedLast.rawValue
        let didRender = storage.withUnsafeMutableBytes { buffer in
            guard
                let baseAddress = buffer.baseAddress,
                let context = CGContext(
                    data: baseAddress,
                    width: width,
                    height: height,
                    bitsPerComponent: Constant.bitsPerComponent,
                    bytesPerRow: width * Constant.bytesPerPixel,
                    space: colorSpace,
                    bitmapInfo: bitmapInfo,
                )
            else { return false }

            context.draw(
                cgImage,
                in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)),
            )
            return true
        }
        guard didRender else { return nil }

        self.width = width
        self.height = height
        pixels = storage
    }

    // MARK: Internal

    let width: Int
    let height: Int

    func bounds(
        matching color: GeometryMarkerColor,
        largestComponentCount: Int = 1,
    ) -> CGRect? {
        guard largestComponentCount > 0 else { return nil }
        let selectedComponents = matchingComponents(color)
            .sorted { $0.pixelCount > $1.pixelCount }
            .prefix(largestComponentCount)
        return selectedComponents.reduce(nil as CGRect?) { bounds, component in
            bounds?.union(component.bounds) ?? component.bounds
        }
    }

    func componentBounds(matching color: GeometryMarkerColor) -> [CGRect] {
        matchingComponents(color)
            .sorted { $0.pixelCount > $1.pixelCount }
            .map(\.bounds)
    }

    func pointBounds(
        for pixelBounds: CGRect,
        pointSize: CGSize,
    ) -> CGRect {
        let horizontalScale = pointSize.width / CGFloat(width)
        let verticalScale = pointSize.height / CGFloat(height)
        return CGRect(
            x: pixelBounds.minX * horizontalScale,
            y: pixelBounds.minY * verticalScale,
            width: pixelBounds.width * horizontalScale,
            height: pixelBounds.height * verticalScale,
        )
    }

    func estimatedTopLeftCornerRadius(
        matching color: GeometryMarkerColor,
        pointSize: CGSize,
    ) -> CGFloat? {
        let horizontalScale = pointSize.width / CGFloat(width)
        let verticalScale = pointSize.height / CGFloat(height)
        let maximumSampleY = min(height / 2, Int(Constant.maximumCornerSample / verticalScale))
        let maximumSampleX = min(width / 2, Int(Constant.maximumCornerSample / horizontalScale))
        let background = rgbSample(x: 0, y: 0)
        var samples = [CGPoint]()

        for y in 0..<maximumSampleY {
            guard
                let boundaryX = interpolatedMarkerBoundaryX(
                    color,
                    over: background,
                    maximumX: maximumSampleX,
                    y: y,
                )
            else { continue }

            samples.append(
                CGPoint(
                    x: boundaryX * horizontalScale,
                    y: (CGFloat(y) + 0.5) * verticalScale,
                )
            )
        }

        guard samples.count >= Constant.minimumCornerSamples else { return nil }

        var bestRadius: CGFloat?
        var bestError = CGFloat.greatestFiniteMagnitude
        var candidate = Constant.minimumCornerRadius
        while candidate <= Constant.maximumCornerRadius {
            let error = samples.reduce(CGFloat.zero) { partialResult, sample in
                let expectedX = expectedRoundedCornerX(y: sample.y, radius: candidate)
                let difference = sample.x - expectedX
                return partialResult + difference * difference
            } / CGFloat(samples.count)

            if error < bestError {
                bestError = error
                bestRadius = candidate
            }
            candidate += Constant.cornerRadiusStep
        }

        return bestRadius
    }

    // MARK: Private

    private enum Constant {
        static let bytesPerPixel = 4
        static let bitsPerComponent = 8
        static let minimumCornerSamples = 8
        static let maximumCornerSample: CGFloat = 14
        static let minimumCornerRadius: CGFloat = 4
        static let maximumCornerRadius: CGFloat = 12
        static let cornerRadiusStep: CGFloat = 0.1
        static let antialiasedEdgeCoverage = 0.5
    }

    private struct MatchingComponent {
        let bounds: CGRect
        let pixelCount: Int
    }

    private struct RGBSample {
        let red: Double
        let green: Double
        let blue: Double
    }

    private let pixels: [UInt8]

    private func interpolatedMarkerBoundaryX(
        _ color: GeometryMarkerColor,
        over background: RGBSample,
        maximumX: Int,
        y: Int,
    ) -> CGFloat? {
        guard maximumX > 0 else { return nil }
        var previousCoverage = geometryMarkerCoverage(color, over: background, x: 0, y: y)
        if previousCoverage >= Constant.antialiasedEdgeCoverage {
            return 0.5
        }

        for x in 1..<maximumX {
            let coverage = geometryMarkerCoverage(color, over: background, x: x, y: y)
            guard coverage >= Constant.antialiasedEdgeCoverage else {
                previousCoverage = coverage
                continue
            }

            let coverageDelta = coverage - previousCoverage
            let interpolation = coverageDelta > 0
                ? (Constant.antialiasedEdgeCoverage - previousCoverage) / coverageDelta
                : 0
            return CGFloat(x) - 0.5 + CGFloat(interpolation)
        }

        return nil
    }

    private func geometryMarkerCoverage(
        _ color: GeometryMarkerColor,
        over background: RGBSample,
        x: Int,
        y: Int,
    ) -> Double {
        let actual = rgbSample(x: x, y: y)
        let redDelta = Double(color.red) - background.red
        let greenDelta = Double(color.green) - background.green
        let blueDelta = Double(color.blue) - background.blue
        let squaredMarkerDistance = redDelta * redDelta
            + greenDelta * greenDelta
            + blueDelta * blueDelta
        guard squaredMarkerDistance > 0 else { return 0 }

        let projectedDistance = (actual.red - background.red) * redDelta
            + (actual.green - background.green) * greenDelta
            + (actual.blue - background.blue) * blueDelta
        return projectedDistance / squaredMarkerDistance
    }

    private func rgbSample(
        x: Int,
        y: Int,
    ) -> RGBSample {
        let offset = (y * width + x) * Constant.bytesPerPixel
        return RGBSample(
            red: Double(pixels[offset]),
            green: Double(pixels[offset + 1]),
            blue: Double(pixels[offset + 2]),
        )
    }

    private func matchingComponents(_ color: GeometryMarkerColor) -> [MatchingComponent] {
        let pixelCount = width * height
        var matchingPixels = [Bool](repeating: false, count: pixelCount)
        for y in 0..<height {
            for x in 0..<width {
                matchingPixels[y * width + x] = matches(color, x: x, y: y)
            }
        }

        var visited = [Bool](repeating: false, count: pixelCount)
        var queue = [Int]()
        var components = [MatchingComponent]()

        for startingIndex in 0..<pixelCount where matchingPixels[startingIndex] && !visited[startingIndex] {
            queue.removeAll(keepingCapacity: true)
            queue.append(startingIndex)
            visited[startingIndex] = true
            var cursor = 0
            var minimumX = width
            var minimumY = height
            var maximumX = -1
            var maximumY = -1

            while cursor < queue.count {
                let index = queue[cursor]
                cursor += 1
                let x = index % width
                let y = index / width
                minimumX = min(minimumX, x)
                minimumY = min(minimumY, y)
                maximumX = max(maximumX, x)
                maximumY = max(maximumY, y)

                if x > 0 {
                    enqueue(index - 1, matchingPixels: matchingPixels, visited: &visited, queue: &queue)
                }
                if x + 1 < width {
                    enqueue(index + 1, matchingPixels: matchingPixels, visited: &visited, queue: &queue)
                }
                if y > 0 {
                    enqueue(index - width, matchingPixels: matchingPixels, visited: &visited, queue: &queue)
                }
                if y + 1 < height {
                    enqueue(index + width, matchingPixels: matchingPixels, visited: &visited, queue: &queue)
                }
            }

            components.append(
                MatchingComponent(
                    bounds: CGRect(
                        x: CGFloat(minimumX),
                        y: CGFloat(minimumY),
                        width: CGFloat(maximumX - minimumX + 1),
                        height: CGFloat(maximumY - minimumY + 1),
                    ),
                    pixelCount: queue.count,
                )
            )
        }

        return components
    }

    private func enqueue(
        _ index: Int,
        matchingPixels: [Bool],
        visited: inout [Bool],
        queue: inout [Int],
    ) {
        guard matchingPixels[index], !visited[index] else { return }
        visited[index] = true
        queue.append(index)
    }

    private func matches(
        _ color: GeometryMarkerColor,
        x: Int,
        y: Int,
    ) -> Bool {
        let offset = (y * width + x) * Constant.bytesPerPixel
        return pixels[offset + 3] > 200
            && color.matches(
                red: pixels[offset],
                green: pixels[offset + 1],
                blue: pixels[offset + 2],
            )
    }

    private func expectedRoundedCornerX(
        y: CGFloat,
        radius: CGFloat,
    ) -> CGFloat {
        guard y < radius else { return 0 }
        let verticalDistance = radius - y
        return radius - sqrt(max(0, radius * radius - verticalDistance * verticalDistance))
    }

}
