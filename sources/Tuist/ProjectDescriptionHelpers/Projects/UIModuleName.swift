import ProjectDescription

// MARK: - UIModuleName

enum UIModuleName: String {
    case DesignSystem
    case UIComponent
    case DesignSystemTests
    case UIComponentTests
    case UIComponentLayoutHarness
    case UIComponentUITests
}

extension UIModuleName {
    var sourceDirectory: String {
        let directoryName = rawValue.droppingPrefix(ProjectName.UI.rawValue)
        return switch self {
        case .DesignSystem,
             .UIComponent,
             .UIComponentLayoutHarness:
            directoryName
        case .DesignSystemTests:
            "\(directoryName.droppingSuffix("Tests"))"
        case .UIComponentTests:
            "\(directoryName.droppingSuffix("Tests"))/Unit"
        case .UIComponentUITests:
            "\(directoryName.droppingSuffix("UITests"))/UI"
        }
    }
}

// MARK: - DesignSystemFontFamily

private enum DesignSystemFontFamily: CaseIterable {
    case notoSansKR
    case plusJakartaSans

    // MARK: Internal

    var directoryName: String {
        switch self {
        case .notoSansKR:
            "Noto_Sans_KR"
        case .plusJakartaSans:
            "Plus_Jakarta_Sans"
        }
    }

    var postScriptNamePrefix: String {
        switch self {
        case .notoSansKR:
            "NotoSansKR"
        case .plusJakartaSans:
            "PlusJakartaSans"
        }
    }

    var resourceFileElements: [ResourceFileElement] {
        Weight.allCases.map {
            .glob(
                pattern: "\(UIModuleName.DesignSystem.sourceDirectory)/Font/\(directoryName)/static/\(postScriptNamePrefix)-\($0.rawValue).ttf"
            )
        }
    }

    // MARK: Private

    private enum Weight: String, CaseIterable {
        case regular = "Regular"
        case medium = "Medium"
        case bold = "Bold"
    }
}

extension UIModuleName {

    // MARK: Internal

    static let targets: [Target] = [
        .module(
            name: UIModuleName.UIComponent.rawValue,
            sourceDirectory: UIModuleName.UIComponent.sourceDirectory,
            resources: Self.uiComponentImageResources,
            dependencies: [
                .target(name: UIModuleName.DesignSystem.rawValue),
                .external(.Lottie),
            ],
        ),
        .module(
            name: UIModuleName.DesignSystem.rawValue,
            sourceDirectory: UIModuleName.DesignSystem.sourceDirectory,
            resources: Self.designSystemFontResources,
        ),
        .testModule(
            name: UIModuleName.DesignSystemTests.rawValue,
            sourceDirectory: UIModuleName.DesignSystemTests.sourceDirectory,
            productionTarget: .target(name: UIModuleName.DesignSystem.rawValue),
        ),
        .testModule(
            name: UIModuleName.UIComponentTests.rawValue,
            sourceDirectory: UIModuleName.UIComponentTests.sourceDirectory,
            productionTarget: .target(name: UIModuleName.UIComponent.rawValue),
        ),
        .target(
            name: UIModuleName.UIComponentLayoutHarness.rawValue,
            destinations: .iOS,
            product: .app,
            bundleId: "com.nexters.hytime.gitit.uicomponentlayoutharness",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .extendingDefault(with: [
                "UIApplicationSceneManifest": [
                    "UIApplicationSupportsMultipleScenes": false
                ],
                "UILaunchScreen": [:],
            ]),
            sources: ["\(UIModuleName.UIComponentLayoutHarness.sourceDirectory)/**"],
            dependencies: [
                .target(name: UIModuleName.UIComponent.rawValue),
                .target(name: UIModuleName.DesignSystem.rawValue),
            ],
            settings: .settings(base: [
                "CODE_SIGN_STYLE": "Automatic",
                "DEVELOPMENT_TEAM": "6924CABL23",
                "ENABLE_PREVIEWS": "YES",
                "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                "SWIFT_VERSION": "5.0",
            ]),
        ),
        .target(
            name: UIModuleName.UIComponentUITests.rawValue,
            destinations: .iOS,
            product: .uiTests,
            bundleId: "com.nexters.hytime.gitit.uicomponentuitests",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .default,
            sources: ["Tests/\(UIModuleName.UIComponentUITests.sourceDirectory)/**"],
            dependencies: [
                .target(name: UIModuleName.UIComponentLayoutHarness.rawValue)
            ],
            settings: .settings(base: [
                "CODE_SIGN_STYLE": "Automatic",
                "DEVELOPMENT_TEAM": "6924CABL23",
                "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                "SWIFT_VERSION": "5.0",
            ]),
        ),
    ]

    // MARK: Private

    private static let designSystemFontResources = ResourceFileElements.resources(
        DesignSystemFontFamily.allCases.flatMap(\.resourceFileElements)
    )

    private static let uiComponentImageResources = ResourceFileElements.resources(
        [.glob(pattern: "\(UIModuleName.UIComponent.sourceDirectory)/Resources/**")]
    )

}

extension TargetDependency {
    static func fromUI(_ name: UIModuleName) -> Self {
        .project(
            target: name.rawValue,
            path: "../UI",
        )
    }
}
