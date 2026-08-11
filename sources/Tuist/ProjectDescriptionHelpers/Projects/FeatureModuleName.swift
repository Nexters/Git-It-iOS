import ProjectDescription

// MARK: - FeatureModuleName

enum FeatureModuleName: String, CaseIterable {
    case Feature
    case FeatureAuthentication
    case FeatureAuthenticationTests
}

extension FeatureModuleName {
    var target: Target {
        switch self {
        case .Feature:
            .module(
                name: rawValue,
                dependencies: [
                    .fromDomain(.Domain),
                    .fromUI(.UIComponent),
                    .external(.ComposableArchitecture),
                ],
            )

        case .FeatureAuthentication:
            .module(
                name: rawValue,
                dependencies: [
                    .fromDomain(.DomainAuthentication),
                    .fromUI(.UIComponent),
                    .external(.ComposableArchitecture),
                ],
            )

        case .FeatureAuthenticationTests:
            .testModule(
                name: rawValue,
                productionTarget: .target(
                    name: FeatureModuleName.FeatureAuthentication.rawValue
                ),
                additionalDependencies: [
                    .fromDomain(.DomainAuthentication),
                    .external(.ComposableArchitecture),
                ],
            )
        }
    }
}

extension TargetDependency {
    static func fromFeature(_ name: FeatureModuleName) -> Self {
        .project(target: name.rawValue, path: "../Feature")
    }
}
