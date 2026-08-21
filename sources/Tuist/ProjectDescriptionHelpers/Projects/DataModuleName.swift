import ProjectDescription

// MARK: - DataModuleName

enum DataModuleName: String, CaseIterable {
    case DataAuthentication
    case DataAuthenticationTests
    case DataLearningProject
    case DataLearningProjectTests
    case DataMember
    case DataMemberTests
}

extension DataModuleName {
    var sourceDirectory: String {
        let directoryName = rawValue.droppingPrefix(ProjectName.Data.rawValue)
        return switch self {
        case .DataAuthentication,
             .DataLearningProject,
             .DataMember:
            directoryName
        case .DataAuthenticationTests,
             .DataLearningProjectTests,
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
            )

        case .DataLearningProjectTests:
            .testModule(
                name: rawValue,
                sourceDirectory: sourceDirectory,
                productionTarget: .target(
                    name: DataModuleName.DataLearningProject.rawValue
                ),
            )

        case .DataMember:
            .module(
                name: rawValue,
                sourceDirectory: sourceDirectory,
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
