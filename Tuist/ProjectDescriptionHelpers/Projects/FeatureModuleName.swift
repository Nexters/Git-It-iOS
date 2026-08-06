import ProjectDescription

enum FeatureModuleName: String, CaseIterable {
    case Feature
}

extension FeatureModuleName {
    var target: Target {
        .module(
            name: rawValue,
            dependencies: [
                .fromDomain(.Domain),
                .fromUI(.DesignSystem),
                .fromUI(.UIComponent),
                .external(.ComposableArchitecture),
            ]
        )
    }
}

extension TargetDependency {
    static func fromFeature(_ name: FeatureModuleName) -> Self {
        .project(target: name.rawValue, path: "../Features")
    }
}
