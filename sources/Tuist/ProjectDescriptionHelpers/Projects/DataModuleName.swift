import ProjectDescription

// MARK: - DataModuleName

enum DataModuleName: String, CaseIterable {
    case DataAuthentication
    case DataAuthenticationTests
}

extension DataModuleName {
    var sourceDirectory: String {
        let directoryName = rawValue.droppingPrefix(ProjectName.Data.rawValue)
        return switch self {
        case .DataAuthentication:
            directoryName
        case .DataAuthenticationTests:
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
        }
    }
}

extension TargetDependency {
    static func fromData(_ name: DataModuleName) -> Self {
        .project(
            target: name.rawValue,
            path: "../Data"
        )
    }
}
