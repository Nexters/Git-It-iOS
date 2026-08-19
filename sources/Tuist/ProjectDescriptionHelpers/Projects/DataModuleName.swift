import ProjectDescription

// MARK: - DataModuleName

enum DataModuleName: String, CaseIterable {
    case DataAuthentication
    case DataAuthenticationTests
    case DataLearningProject
    case DataLearningProjectTests
}

extension DataModuleName {
    var target: Target {
        switch self {
        case .DataAuthentication:
            .module(
                name: rawValue
            )

        case .DataAuthenticationTests:
            .testModule(
                name: rawValue,
                productionTarget: .target(
                    name: DataModuleName.DataAuthentication.rawValue
                ),
            )

        case .DataLearningProject:
            .module(
                name: rawValue
            )

        case .DataLearningProjectTests:
            .testModule(
                name: rawValue,
                productionTarget: .target(
                    name: DataModuleName.DataLearningProject.rawValue
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
