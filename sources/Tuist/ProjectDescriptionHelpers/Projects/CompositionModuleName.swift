import ProjectDescription

// MARK: - CompositionModuleName

enum CompositionModuleName: String, CaseIterable {
    case CompositionShared
    case CompositionAuthentication
    case CompositionAuthenticationTests
    case CompositionLearningProject
    case CompositionLearningProjectTests
    case CompositionMember
    case CompositionMemberTests
    case CompositionApp
    case CompositionAppTests
    case CompositionShareExtension
    case CompositionShareExtensionTests
}

extension CompositionModuleName {
    var sourceDirectory: String {
        let directoryName = rawValue.droppingPrefix(ProjectName.Composition.rawValue)
        return switch self {
        case .CompositionShared,
             .CompositionAuthentication,
             .CompositionLearningProject,
             .CompositionMember,
             .CompositionApp,
             .CompositionShareExtension:
            directoryName
        case .CompositionAuthenticationTests,
             .CompositionLearningProjectTests,
             .CompositionMemberTests,
             .CompositionAppTests,
             .CompositionShareExtensionTests:
            directoryName.droppingSuffix("Tests")
        }
    }

    var target: Target {
        switch self {
        case .CompositionShared:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                dependencies: [
                    .fromInfrastructure(.InfrastructureNetworkClient)
                ],
            )

        case .CompositionAuthentication:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                dependencies: [
                    .target(name: CompositionModuleName.CompositionShared.rawValue),
                    .fromDomain(.DomainAuthentication),
                    .fromData(.DataAuthentication),
                    .fromData(.DataLegalConsent),
                    .fromInfrastructure(.InfrastructureNetworkClient),
                    .fromInfrastructure(.InfrastructureAuthentication),
                    .fromInfrastructure(.InfrastructureStorage),
                ],
            )

        case .CompositionAuthenticationTests:
            .testModule(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                productionTarget: .target(
                    name: CompositionModuleName.CompositionAuthentication.rawValue
                ),
            )

        case .CompositionLearningProject:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                dependencies: [
                    .target(name: CompositionModuleName.CompositionShared.rawValue),
                    .fromDomain(.DomainLearningProject),
                    .fromData(.DataLearningProject),
                    .fromData(.DataExternalRepository),
                    .fromInfrastructure(.InfrastructureNetworkClient),
                    .fromInfrastructure(.InfrastructureStorage),
                    .fromInfrastructure(.InfrastructureLocalNotification),
                ],
            )

        case .CompositionLearningProjectTests:
            .testModule(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                productionTarget: .target(
                    name: CompositionModuleName.CompositionLearningProject.rawValue
                ),
            )

        case .CompositionMember:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                dependencies: [
                    .target(name: CompositionModuleName.CompositionShared.rawValue),
                    .fromDomain(.DomainAuthentication),
                    .fromDomain(.DomainMember),
                    .fromData(.DataMember),
                    .fromInfrastructure(.InfrastructureNetworkClient),
                    .fromInfrastructure(.InfrastructureAuthentication),
                ],
            )

        case .CompositionMemberTests:
            .testModule(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                productionTarget: .target(
                    name: CompositionModuleName.CompositionMember.rawValue
                ),
            )

        case .CompositionApp:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                dependencies: [
                    .target(name: CompositionModuleName.CompositionAuthentication.rawValue),
                    .target(name: CompositionModuleName.CompositionLearningProject.rawValue),
                    .target(name: CompositionModuleName.CompositionMember.rawValue),
                    .fromDomain(.DomainAuthentication),
                    .fromDomain(.DomainLearningProject),
                    .fromDomain(.DomainMember),
                    .fromInfrastructure(.InfrastructureNetworkClient),
                    .fromInfrastructure(.InfrastructureAuthentication),
                    .fromInfrastructure(.InfrastructurePushMessaging),
                ],
            )

        case .CompositionAppTests:
            .testModule(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                productionTarget: .target(
                    name: CompositionModuleName.CompositionApp.rawValue
                ),
                additionalDependencies: [
                    .target(name: CompositionModuleName.CompositionAuthentication.rawValue),
                    .target(name: CompositionModuleName.CompositionLearningProject.rawValue),
                    .target(name: CompositionModuleName.CompositionMember.rawValue),
                    .fromData(.DataAuthentication),
                ],
            )

        case .CompositionShareExtension:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                dependencies: [
                    .target(name: CompositionModuleName.CompositionAuthentication.rawValue),
                    .target(name: CompositionModuleName.CompositionLearningProject.rawValue),
                    .fromDomain(.DomainAuthentication),
                    .fromDomain(.DomainLearningProject),
                    .fromInfrastructure(.InfrastructureNetworkClient),
                    .fromInfrastructure(.InfrastructureAuthentication),
                    .fromInfrastructure(.InfrastructureStorage),
                    .fromInfrastructure(.InfrastructureLocalNotification),
                ],
            )

        case .CompositionShareExtensionTests:
            .testModule(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                productionTarget: .target(
                    name: CompositionModuleName.CompositionShareExtension.rawValue
                ),
                additionalDependencies: [
                    .target(name: CompositionModuleName.CompositionAuthentication.rawValue),
                    .target(name: CompositionModuleName.CompositionLearningProject.rawValue),
                    .fromData(.DataAuthentication),
                    .fromData(.DataLearningProject),
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
