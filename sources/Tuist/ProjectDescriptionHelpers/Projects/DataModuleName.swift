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
    case DataShared
    case DataSharedTests
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
            .DataMember,
            .DataShared:
            directoryName
        case
            .DataAuthenticationTests,
            .DataExternalRepositoryTests,
            .DataLearningProjectTests,
            .DataLegalConsentTests,
            .DataMemberTests,
            .DataSharedTests:
            "\(directoryName.droppingSuffix("Tests"))"
        }
    }

    static let packageName = "GitItData"

    var target: Target {
        switch self {
        case .DataAuthentication:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                packageName: Self.packageName,
                dependencies: [
                    .target(name: DataModuleName.DataShared.rawValue),
                    .fromInfrastructure(.InfrastructureNetworkClient),
                    .fromInfrastructure(.InfrastructureAuthentication),
                    .fromInfrastructure(.InfrastructureStorage),
                ],
            )

        case .DataAuthenticationTests:
            .testModule(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                packageName: Self.packageName,
                productionTarget: .target(
                    name: DataModuleName.DataAuthentication.rawValue
                ),
                additionalDependencies: [
                    .fromInfrastructure(.InfrastructureAuthentication),
                    .fromInfrastructure(.InfrastructureStorage),
                ],
            )

        case .DataLearningProject:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                packageName: Self.packageName,
                dependencies: [
                    .target(name: DataModuleName.DataShared.rawValue),
                    .fromInfrastructure(.InfrastructureNetworkClient),
                ],
            )

        case .DataExternalRepository:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                packageName: Self.packageName,
                dependencies: [
                    .target(name: DataModuleName.DataShared.rawValue),
                    .fromInfrastructure(.InfrastructureNetworkClient),
                ],
            )

        case .DataExternalRepositoryTests:
            .testModule(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                packageName: Self.packageName,
                productionTarget: .target(
                    name: DataModuleName.DataExternalRepository.rawValue
                ),
            )

        case .DataLearningProjectTests:
            .testModule(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                packageName: Self.packageName,
                productionTarget: .target(
                    name: DataModuleName.DataLearningProject.rawValue
                ),
                additionalDependencies: [
                    .fromInfrastructure(.InfrastructureNetworkClient)
                ],
            )

        case .DataLegalConsent:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                packageName: Self.packageName,
                dependencies: [
                    .target(name: DataModuleName.DataShared.rawValue),
                    .fromInfrastructure(.InfrastructureStorage),
                ],
            )

        case .DataLegalConsentTests:
            .testModule(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                packageName: Self.packageName,
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
                packageName: Self.packageName,
                dependencies: [
                    .target(name: DataModuleName.DataShared.rawValue),
                    .fromInfrastructure(.InfrastructureNetworkClient),
                ],
            )

        case .DataMemberTests:
            .testModule(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                packageName: Self.packageName,
                productionTarget: .target(
                    name: DataModuleName.DataMember.rawValue
                ),
            )

        case .DataShared:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                packageName: Self.packageName,
                dependencies: [
                    .fromInfrastructure(.InfrastructureAuthentication),
                    .fromInfrastructure(.InfrastructureNetworkClient),
                    .fromInfrastructure(.InfrastructureStorage),
                ],
            )

        case .DataSharedTests:
            .testModule(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                packageName: Self.packageName,
                productionTarget: .target(
                    name: DataModuleName.DataShared.rawValue
                ),
                additionalDependencies: [
                    .fromInfrastructure(.InfrastructureAuthentication),
                    .fromInfrastructure(.InfrastructureNetworkClient),
                    .fromInfrastructure(.InfrastructureStorage),
                ],
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
