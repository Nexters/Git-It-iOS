import ProjectDescription

// MARK: - DomainModuleName

enum DomainModuleName: String, CaseIterable {
    case DomainAuthentication
    case DomainAuthenticationTests
    case DomainLearningProject
    case DomainLearningProjectTests
    case DomainMember
    case DomainMemberTests
}

extension DomainModuleName {
    var sourceDirectory: String {
        let directoryName = rawValue.droppingPrefix(ProjectName.Domain.rawValue)
        return switch self {
        case .DomainAuthentication,
             .DomainLearningProject,
             .DomainMember:
            directoryName

        case .DomainAuthenticationTests,
             .DomainLearningProjectTests,
             .DomainMemberTests:
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
