import ProjectDescription

// MARK: - DomainModuleName

enum DomainModuleName: String, CaseIterable {
    case DomainAuthentication
    case DomainAuthenticationTests
}

extension DomainModuleName {
    var target: Target {
        switch self {
        case .DomainAuthentication:
            .module(name: rawValue)

        case .DomainAuthenticationTests:
            .testModule(
                name: rawValue,
                productionTarget: .target(
                    name: DomainModuleName.DomainAuthentication.rawValue
                ),
            )
        }
    }
}

extension TargetDependency {
    static func fromDomain(_ name: DomainModuleName) -> Self {
        .project(target: name.rawValue, path: "../Domain")
    }
}
