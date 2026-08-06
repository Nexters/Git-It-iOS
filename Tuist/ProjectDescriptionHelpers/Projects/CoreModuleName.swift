import ProjectDescription

// MARK: - CoreModuleName

enum CoreModuleName: String {
    case Utility
}

extension CoreModuleName {
    static let targets: [Target] = [
        .module(
            name: CoreModuleName.Utility.rawValue
        )
    ]
}

extension TargetDependency {
    static func fromCore(_ name: CoreModuleName) -> Self {
        .project(target: name.rawValue, path: "../Core")
    }
}
