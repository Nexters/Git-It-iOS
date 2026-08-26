import ProjectDescription

// MARK: - FeatureModuleName

enum FeatureModuleName: String, CaseIterable {
    case Feature
    case FeatureTests
}

extension FeatureModuleName {
    var sourceDirectory: String {
        let directoryName = rawValue.droppingPrefix(ProjectName.Feature.rawValue)
        return switch self {
        case .Feature:
            directoryName.isEmpty ? "Presentation" : directoryName
        case .FeatureTests:
            directoryName.droppingSuffix("Tests")
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

        case .FeatureTests:
            .testModule(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                productionTarget: .target(
                    name: FeatureModuleName.Feature.rawValue
                ),
                additionalDependencies: [
                    .external(.ComposableArchitecture)
                ],
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
