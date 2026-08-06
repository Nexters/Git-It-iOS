import ProjectDescription

enum DataModuleName: String, CaseIterable {
    case Data
}

extension DataModuleName {
    var target: Target {
        .module(
            name: rawValue,
            dependencies: [
                .fromCore(.Auth),
                .fromCore(.Cache),
                .fromCore(.HTTPClient),
                .fromDomain(.Domain),
                .fromUtility(.Utility),
            ]
        )
    }
}

extension TargetDependency {
    static func fromData(_ name: DataModuleName) -> Self {
        .project(target: name.rawValue, path: "../Data")
    }
}
