import ProjectDescription

enum DomainModuleName: String, CaseIterable {
    case Domain
}

extension DomainModuleName {
    var target: Target {
        .module(name: rawValue)
    }
}

extension TargetDependency {
    static func fromDomain(_ name: DomainModuleName) -> Self {
        .project(target: name.rawValue, path: "../Domain")
    }
}
