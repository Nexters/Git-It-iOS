import ProjectDescription

// MARK: - CompositionModuleName

enum CompositionModuleName: String, CaseIterable {
    case CompositionAdapter
    case CompositionAdapterTests
}

extension CompositionModuleName {
    var sourceDirectory: String {
        let directoryName = rawValue.droppingPrefix(ProjectName.Composition.rawValue)
        return switch self {
        case .CompositionAdapter:
            directoryName
        case .CompositionAdapterTests:
            directoryName.droppingSuffix("Tests")
        }
    }

    var target: Target {
        switch self {
        case .CompositionAdapter:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                dependencies: [
                    .fromDomain(.DomainAuthentication),
                    .fromDomain(.DomainLearningProject),
                    .fromDomain(.DomainMember),
                    .fromData(.DataAuthentication),
                    .fromData(.DataLearningProject),
                    .fromData(.DataExternalRepository),
                    .fromData(.DataLegalConsent),
                    .fromData(.DataMember),
                    .fromInfrastructure(.InfrastructureNetworkClient),
                    .fromInfrastructure(.InfrastructureAuthentication),
                    .fromInfrastructure(.InfrastructureCache),
                ],
            )

        case .CompositionAdapterTests:
            .testModule(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                productionTarget: .target(
                    name: CompositionModuleName.CompositionAdapter.rawValue
                ),
            )
        }
    }
}

extension TargetDependency {
    static func fromComposition(_ name: CompositionModuleName) -> Self {
        .project(
            target: name.rawValue,
            path: "../Composition",
        )
    }
}
