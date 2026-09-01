import ProjectDescription

// MARK: - DataModuleName

enum DataModuleName: String, CaseIterable {
    case DataAuthentication
    case DataAuthenticationTests
    case DataExternalRepository
    case DataExternalRepositoryTests
    case DataLearningProject
    case DataLearningProjectTests
    case DataLegalConsent
    case DataLegalConsentTests
    case DataMember
    case DataMemberTests
}

extension DataModuleName {
    var sourceDirectory: String {
        let directoryName = rawValue.droppingPrefix(ProjectName.Data.rawValue)
        return switch self {
        case
            .DataAuthentication,
            .DataExternalRepository,
            .DataLearningProject,
            .DataLegalConsent,
            .DataMember:
            directoryName
        case
            .DataAuthenticationTests,
            .DataExternalRepositoryTests,
            .DataLearningProjectTests,
            .DataLegalConsentTests,
            .DataMemberTests:
            "\(directoryName.droppingSuffix("Tests"))"
        }
    }

    var target: Target {
        switch self {
        case .DataAuthentication:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                dependencies: [
                    .fromInfrastructure(.InfrastructureNetworkClient),
                    .fromInfrastructure(.InfrastructureAuthentication),
                ],
            )

        case .DataAuthenticationTests:
            .testModule(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                productionTarget: .target(
                    name: DataModuleName.DataAuthentication.rawValue
                ),
            )

        case .DataLearningProject:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                dependencies: [
                    .fromInfrastructure(.InfrastructureNetworkClient),
                    .fromInfrastructure(.InfrastructureStorage),
                ],
            )

        case .DataExternalRepository:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                dependencies: [
                    .fromInfrastructure(.InfrastructureNetworkClient)
                ],
            )

        case .DataExternalRepositoryTests:
            .testModule(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                productionTarget: .target(
                    name: DataModuleName.DataExternalRepository.rawValue
                ),
            )

        case .DataLearningProjectTests:
            .testModule(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                productionTarget: .target(
                    name: DataModuleName.DataLearningProject.rawValue
                ),
                additionalDependencies: [
                    .fromInfrastructure(.InfrastructureStorage)
                ],
            )

        case .DataLegalConsent:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                dependencies: [
                    .fromInfrastructure(.InfrastructureStorage)
                ],
            )

        case .DataLegalConsentTests:
            .testModule(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                productionTarget: .target(
                    name: DataModuleName.DataLegalConsent.rawValue
                ),
                additionalDependencies: [
                    .fromInfrastructure(.InfrastructureStorage)
                ],
            )

        case .DataMember:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                dependencies: [
                    .fromInfrastructure(.InfrastructureNetworkClient)
                ],
            )

        case .DataMemberTests:
            .testModule(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                productionTarget: .target(
                    name: DataModuleName.DataMember.rawValue
                ),
            )
        }
    }
}

extension TargetDependency {
    static func fromData(_ name: DataModuleName) -> Self {
        .project(
            target: name.rawValue,
            path: "../Data",
        )
    }
}
