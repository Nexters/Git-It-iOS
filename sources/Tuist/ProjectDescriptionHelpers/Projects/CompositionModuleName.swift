import ProjectDescription

// MARK: - CompositionModuleName

enum CompositionModuleName: String, CaseIterable {
    case CompositionAdepter
    case CompositionAdepterTests
}

extension CompositionModuleName {
    var sourceDirectory: String {
        let directoryName = rawValue.droppingPrefix(ProjectName.Composition.rawValue)
        return switch self {
        case .CompositionAdepter:
            directoryName
        case .CompositionAdepterTests:
            directoryName.droppingSuffix("Tests")
        }
    }

    var target: Target {
        switch self {
        case .CompositionAdepter:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                dependencies: [
                    .fromDomain(.DomainLearningProject),
                    .fromData(.DataLearningProject),
                    .fromInfrastructure(.InfrastructureNetworkClient),
                ],
            )

        case .CompositionAdepterTests:
            .testModule(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                productionTarget: .target(
                    name: CompositionModuleName.CompositionAdepter.rawValue
                ),
                additionalDependencies: [
                    .fromDomain(.DomainLearningProject),
                    .fromData(.DataLearningProject),
                    .fromInfrastructure(.InfrastructureNetworkClient),
                ],
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
