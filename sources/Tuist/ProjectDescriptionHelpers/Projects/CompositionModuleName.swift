import ProjectDescription

// MARK: - CompositionModuleName

enum CompositionModuleName: String, CaseIterable {
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
        case .CompositionAuthentication,
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
        case .CompositionAuthentication:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                dependencies: [
                    .fromDomain(.DomainIdentifier),
                    .fromDomain(.DomainAccount),
                    .fromData(.DataAuthentication),
                    .fromData(.DataLegalConsent),
                    .fromData(.DataShared),
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
                    .fromDomain(.DomainIdentifier),
                    .fromDomain(.DomainAppSetting),
                    .fromDomain(.DomainExternalRepository),
                    .fromDomain(.DomainQuizDetail),
                    .fromDomain(.DomainProject),
                    .fromDomain(.DomainProjectGeneration),
                    .fromData(.DataLearningProject),
                    .fromData(.DataExternalRepository),
                    .fromData(.DataNotification),
                    .fromData(.DataShared),
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
                    .fromDomain(.DomainIdentifier),
                    .fromDomain(.DomainAccount),
                    .fromDomain(.DomainUserInfo),
                    .fromDomain(.DomainAppSetting),
                    .fromData(.DataAuthentication),
                    .fromData(.DataMember),
                    .fromData(.DataShared),
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
                    .fromDomain(.DomainIdentifier),
                    .fromDomain(.DomainAccount),
                    .fromDomain(.DomainUserInfo),
                    .fromDomain(.DomainAppSetting),
                    .fromDomain(.DomainExternalRepository),
                    .fromDomain(.DomainQuizDetail),
                    .fromDomain(.DomainProject),
                    .fromDomain(.DomainProjectGeneration),
                    .fromData(.DataAuthentication),
                    .fromData(.DataExternalRepository),
                    .fromData(.DataLearningProject),
                    .fromData(.DataLegalConsent),
                    .fromData(.DataMember),
                    .fromData(.DataNotification),
                    .fromData(.DataShared),
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
                    .fromDomain(.DomainIdentifier),
                    .fromDomain(.DomainAccount),
                    .fromDomain(.DomainExternalRepository),
                    .fromDomain(.DomainProjectGeneration),
                    .fromData(.DataAuthentication),
                    .fromData(.DataExternalRepository),
                    .fromData(.DataLearningProject),
                    .fromData(.DataNotification),
                    .fromData(.DataShared),
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
