import ProjectDescription

// MARK: - DataModuleName

enum DataModuleName: String, CaseIterable {
    case Data
}

extension DataModuleName {
    var target: Target {
        .module(
            name: rawValue
        )
    }
}

extension TargetDependency {
    static func fromData(_ name: DataModuleName) -> Self {
        .project(target: name.rawValue, path: "../Data")
    }
}
