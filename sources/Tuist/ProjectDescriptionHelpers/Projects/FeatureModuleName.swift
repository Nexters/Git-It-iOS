import ProjectDescription

// MARK: - FeatureModuleName

enum FeatureModuleName: String, CaseIterable {
    case Feature
}

extension FeatureModuleName {
    var target: Target {
        switch self {
        case .Feature:
            .module(
                name: rawValue
            )
        }
    }
}

extension TargetDependency {
    static func fromFeature(_ name: FeatureModuleName) -> Self {
        .project(
            target: name.rawValue,
            path: "../Feature"
        )
    }
}
