import ProjectDescription

// MARK: - UIModuleName

enum UIModuleName: String {
    case DesignSystem
    case UIComponent
    case DesignSystemTests
    case UIComponentTests
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
                .target(name: UIModuleName.DesignSystem.rawValue)
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
