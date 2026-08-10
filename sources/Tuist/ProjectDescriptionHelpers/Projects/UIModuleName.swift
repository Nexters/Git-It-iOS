import ProjectDescription

// MARK: - UIModuleName

enum UIModuleName: String {
    case DesignSystem
    case UIComponent
}

extension UIModuleName {
    static let targets: [Target] = [
        .module(
            name: UIModuleName.UIComponent.rawValue,
            dependencies: [
                .target(name: UIModuleName.DesignSystem.rawValue)
            ],
        ),
        .module(
            name: UIModuleName.DesignSystem.rawValue
        ),
    ]
}

extension TargetDependency {
    static func fromUI(_ name: UIModuleName) -> Self {
        .project(target: name.rawValue, path: "../UI")
    }
}
