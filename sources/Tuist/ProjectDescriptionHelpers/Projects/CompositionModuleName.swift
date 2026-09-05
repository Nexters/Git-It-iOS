import ProjectDescription

// MARK: - CompositionModuleName

enum CompositionModuleName: String, CaseIterable {
    case CompositionAdapter
    case CompositionAdapterTests
    case CompositionApp
    case CompositionAppTests
    case CompositionShareExtension
    case CompositionShareExtensionTests
}

extension CompositionModuleName {
    var sourceDirectory: String {
        let directoryName = rawValue.droppingPrefix(ProjectName.Composition.rawValue)
        return switch self {
        case .CompositionAdapter,
             .CompositionApp,
             .CompositionShareExtension:
            directoryName
        case .CompositionAdapterTests,
             .CompositionAppTests,
             .CompositionShareExtensionTests:
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
                    .fromInfrastructure(.InfrastructureStorage),
                    .fromInfrastructure(.InfrastructureLocalNotification),
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

        case .CompositionApp:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                dependencies: [
                    .target(name: CompositionModuleName.CompositionAdapter.rawValue),
                    .fromDomain(.DomainAuthentication),
                    .fromDomain(.DomainLearningProject),
                    .fromDomain(.DomainMember),
                    .fromData(.DataExternalRepository),
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
                    .target(name: CompositionModuleName.CompositionAdapter.rawValue)
                ],
            )

        case .CompositionShareExtension:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                dependencies: [
                    .target(name: CompositionModuleName.CompositionAdapter.rawValue),
                    .fromDomain(.DomainLearningProject),
                    .fromInfrastructure(.InfrastructureNetworkClient),
                    .fromInfrastructure(.InfrastructureAuthentication),
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
                    .target(name: CompositionModuleName.CompositionAdapter.rawValue),
                    .fromDomain(.DomainAuthentication),
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
