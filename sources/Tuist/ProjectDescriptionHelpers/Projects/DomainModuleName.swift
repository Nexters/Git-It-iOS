import ProjectDescription

// MARK: - DomainModuleName

enum DomainModuleName: String, CaseIterable {
    case DomainAuthentication
    case DomainAuthenticationTests
    case DomainLearningProject
    case DomainLearningProjectTests
    case DomainMember
    case DomainMemberTests
    case DomainIdentifier
    case DomainIdentifierTests
    case DomainAccount
    case DomainAccountTests
    case DomainUserInfo
    case DomainUserInfoTests
    case DomainAppSetting
    case DomainAppSettingTests
    case DomainExternalRepository
    case DomainExternalRepositoryTests
    case DomainQuizDetail
    case DomainQuizDetailTests
    case DomainProject
    case DomainProjectTests
    case DomainProjectGeneration
    case DomainProjectGenerationTests
}

extension DomainModuleName {
    var sourceDirectory: String {
        let directoryName = rawValue.droppingPrefix(ProjectName.Domain.rawValue)
        return switch self {
        case .DomainAuthentication,
             .DomainLearningProject,
             .DomainMember,
             .DomainIdentifier,
             .DomainAccount,
             .DomainUserInfo,
             .DomainAppSetting,
             .DomainExternalRepository,
             .DomainQuizDetail,
             .DomainProject,
             .DomainProjectGeneration:
            directoryName

        case .DomainAuthenticationTests,
             .DomainLearningProjectTests,
             .DomainMemberTests,
             .DomainIdentifierTests,
             .DomainAccountTests,
             .DomainUserInfoTests,
             .DomainAppSettingTests,
             .DomainExternalRepositoryTests,
             .DomainQuizDetailTests,
             .DomainProjectTests,
             .DomainProjectGenerationTests:
            "\(directoryName.droppingSuffix("Tests"))"
        }
    }

    var target: Target {
        switch self {
        case .DomainAuthentication:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
            )

        case .DomainAuthenticationTests:
            .testModule(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                productionTarget: .target(
                    name: DomainModuleName.DomainAuthentication.rawValue
                ),
            )

        case .DomainLearningProject:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
            )

        case .DomainLearningProjectTests:
            .testModule(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                productionTarget: .target(
                    name: DomainModuleName.DomainLearningProject.rawValue
                ),
            )

        case .DomainMember:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
            )

        case .DomainMemberTests:
            .testModule(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                productionTarget: .target(
                    name: DomainModuleName.DomainMember.rawValue
                ),
            )

        case .DomainIdentifier:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
            )

        case .DomainIdentifierTests:
            .testModule(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                productionTarget: .target(
                    name: DomainModuleName.DomainIdentifier.rawValue
                ),
            )

        case .DomainAccount:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                dependencies: [
                    .target(name: DomainModuleName.DomainIdentifier.rawValue)
                ],
            )

        case .DomainAccountTests:
            .testModule(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                productionTarget: .target(
                    name: DomainModuleName.DomainAccount.rawValue
                ),
            )

        case .DomainUserInfo:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                dependencies: [
                    .target(name: DomainModuleName.DomainIdentifier.rawValue)
                ],
            )

        case .DomainUserInfoTests:
            .testModule(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                productionTarget: .target(
                    name: DomainModuleName.DomainUserInfo.rawValue
                ),
            )

        case .DomainAppSetting:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                dependencies: [
                    .target(name: DomainModuleName.DomainIdentifier.rawValue)
                ],
            )

        case .DomainAppSettingTests:
            .testModule(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                productionTarget: .target(
                    name: DomainModuleName.DomainAppSetting.rawValue
                ),
            )

        case .DomainExternalRepository:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                dependencies: [
                    .target(name: DomainModuleName.DomainIdentifier.rawValue)
                ],
            )

        case .DomainExternalRepositoryTests:
            .testModule(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                productionTarget: .target(
                    name: DomainModuleName.DomainExternalRepository.rawValue
                ),
            )

        case .DomainQuizDetail:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                dependencies: [
                    .target(name: DomainModuleName.DomainIdentifier.rawValue)
                ],
            )

        case .DomainQuizDetailTests:
            .testModule(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                productionTarget: .target(
                    name: DomainModuleName.DomainQuizDetail.rawValue
                ),
            )

        case .DomainProject:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                dependencies: [
                    .target(name: DomainModuleName.DomainIdentifier.rawValue)
                ],
            )

        case .DomainProjectTests:
            .testModule(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                productionTarget: .target(
                    name: DomainModuleName.DomainProject.rawValue
                ),
            )

        case .DomainProjectGeneration:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                dependencies: [
                    .target(name: DomainModuleName.DomainIdentifier.rawValue)
                ],
            )

        case .DomainProjectGenerationTests:
            .testModule(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                productionTarget: .target(
                    name: DomainModuleName.DomainProjectGeneration.rawValue
                ),
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
