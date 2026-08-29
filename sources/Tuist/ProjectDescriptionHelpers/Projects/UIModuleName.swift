import ProjectDescription

// MARK: - UIModuleName

enum UIModuleName: String {
    case DesignSystem
    case UIComponent
    case UIComponentTests
}

extension UIModuleName {
    var sourceDirectory: String {
        let directoryName = rawValue.droppingPrefix(ProjectName.UI.rawValue)
        return switch self {
        case .DesignSystem,
             .UIComponent:
            directoryName
        case .UIComponentTests:
            "\(directoryName.droppingSuffix("Tests"))/Unit"
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
                pattern: "\(UIModuleName.DesignSystem.sourceDirectory)/Resources/Fonts/\(directoryName)/static/\(postScriptNamePrefix)-\($0.rawValue).ttf"
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
            name: UIModuleName.UIComponentTests.rawValue,
            sourceDirectory: UIModuleName.UIComponentTests.sourceDirectory,
            productionTarget: .target(name: UIModuleName.UIComponent.rawValue),
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
