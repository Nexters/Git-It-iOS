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

private enum DesignSystemFontFamily: CaseIterable {
    case notoSansKR
    case plusJakartaSans

    private enum Weight: String, CaseIterable {
        case regular = "Regular"
        case medium = "Medium"
        case bold = "Bold"
    }

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
                pattern: "DesignSystem/Font/\(directoryName)/static/\(postScriptNamePrefix)-\($0.rawValue).ttf",
            )
        }
    }
}

extension UIModuleName {
    private static let designSystemFontResources: ResourceFileElements = .resources(
        DesignSystemFontFamily.allCases.flatMap(\.resourceFileElements),
    )

    private static let uiComponentImageResources: ResourceFileElements = .resources(
        [.glob(pattern: "UIComponent/Resources/**")],
    )

    static let targets: [Target] = [
        .module(
            name: UIModuleName.UIComponent.rawValue,
            resources: Self.uiComponentImageResources,
            dependencies: [
                .target(name: UIModuleName.DesignSystem.rawValue),
                .external(.Lottie),
            ],
        ),
        .module(
            name: UIModuleName.DesignSystem.rawValue,
            resources: Self.designSystemFontResources,
        ),
        .testModule(
            name: UIModuleName.DesignSystemTests.rawValue,
            productionTarget: .target(name: UIModuleName.DesignSystem.rawValue),
        ),
        .testModule(
            name: UIModuleName.UIComponentTests.rawValue,
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
            sources: ["UIComponentLayoutHarness/**"],
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
            sources: ["UIComponentUITests/**"],
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
}

extension TargetDependency {
    static func fromUI(_ name: UIModuleName) -> Self {
        .project(
            target: name.rawValue,
            path: "../UI"
        )
    }
}
