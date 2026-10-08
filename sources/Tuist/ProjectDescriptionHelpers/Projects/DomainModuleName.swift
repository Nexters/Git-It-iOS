import ProjectDescription

// MARK: - DomainModuleName

enum DomainModuleName: String, CaseIterable {
    case DomainUseCaseInterface
    case DomainUseCaseDependency
    case DomainUseCaseImplementation
    case DomainTests
}

extension DomainModuleName {
    var sourceDirectory: String {
        let directoryName = rawValue.droppingPrefix(ProjectName.Domain.rawValue)
        return switch self {
        case .DomainUseCaseInterface,
             .DomainUseCaseDependency,
             .DomainUseCaseImplementation:
            directoryName

        case .DomainTests:
            directoryName.droppingSuffix("Tests")
        }
    }

    var target: Target {
        switch self {
        case .DomainUseCaseInterface:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
            )

        case .DomainUseCaseDependency:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                dependencies: [
                    .target(name: DomainModuleName.DomainUseCaseInterface.rawValue)
                ],
            )

        case .DomainUseCaseImplementation:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                dependencies: [
                    .target(name: DomainModuleName.DomainUseCaseInterface.rawValue),
                    .target(name: DomainModuleName.DomainUseCaseDependency.rawValue),
                ],
            )

        case .DomainTests:
            .testModule(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                productionTarget: .target(
                    name: DomainModuleName.DomainUseCaseImplementation.rawValue
                ),
                additionalDependencies: [
                    .target(name: DomainModuleName.DomainUseCaseInterface.rawValue),
                    .target(name: DomainModuleName.DomainUseCaseDependency.rawValue),
                ],
            )
        }
    }
}

extension TargetDependency {
    static func fromDomain(_ name: DomainModuleName) -> Self {
        .project(
            target: name.rawValue,
            path: "../Domain",
        )
    }
}
