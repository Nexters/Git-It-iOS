import ProjectDescription

// MARK: - FeatureModuleName

enum FeatureModuleName: String, CaseIterable {
    case Feature
}

extension FeatureModuleName {
    var sourceDirectory: String {
        let directoryName = rawValue.droppingPrefix(ProjectName.Feature.rawValue)
        return switch self {
        case .Feature:
            directoryName.isEmpty ? "Presentation" : directoryName
        }
    }

    var target: Target {
        switch self {
        case .Feature:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                dependencies: [
                    .external(.ComposableArchitecture),
                    .fromDomain(.DomainAuthentication),
                    .fromDomain(.DomainLearningProject),
                    .fromDomain(.DomainMember),
                    .fromUI(.DesignSystem),
                    .fromUI(.UIComponent),
                ],
                buildLibraryForDistribution: false,
            )
        }
    }
}

extension TargetDependency {
    static func fromFeature(_ name: FeatureModuleName) -> Self {
        .project(
            target: name.rawValue,
            path: "../Feature",
        )
    }
}
