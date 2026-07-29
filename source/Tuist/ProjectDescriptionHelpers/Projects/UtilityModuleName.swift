import ProjectDescription

enum UtilityModuleName: String, CaseIterable {
    case Utility
}

extension UtilityModuleName {
    var target: Target {
        .module(name: rawValue)
    }
}

extension TargetDependency {
    static func fromUtility(_ name: UtilityModuleName) -> Self {
        .project(target: name.rawValue, path: "../Utility")
    }
}
