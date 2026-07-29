import ProjectDescription

enum CoreModuleName: String, CaseIterable {
    case Auth
    case Cache
    case HTTPClient
}

extension CoreModuleName {
    var target: Target {
        .module(name: rawValue)
    }
}

extension TargetDependency {
    static func fromCore(_ name: CoreModuleName) -> Self {
        .project(target: name.rawValue, path: "../Core")
    }
}
