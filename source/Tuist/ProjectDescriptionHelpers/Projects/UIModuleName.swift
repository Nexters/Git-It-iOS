import ProjectDescription

enum UIModuleName: String, CaseIterable {
    case DesignSystem
    case UIComponent
    case Resource
}

extension UIModuleName {
    var target: Target {
        switch self {
        case .DesignSystem:
            .module(
                name: rawValue,
                dependencies: [
                    .target(name: UIModuleName.Resource.rawValue),
                ]
            )
        case .UIComponent:
            .module(
                name: rawValue,
                dependencies: [
                    .target(name: UIModuleName.DesignSystem.rawValue),
                    .target(name: UIModuleName.Resource.rawValue),
                ]
            )
        case .Resource:
            .resourceBundle(
                name: rawValue,
                resources: ["Resources/**"]
            )
        }
    }
}

extension TargetDependency {
    static func fromUI(_ name: UIModuleName) -> Self {
        .project(target: name.rawValue, path: "../UI")
    }
}
