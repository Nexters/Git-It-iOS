import ProjectDescription

// MARK: - CoreModuleName

enum CoreModuleName: String {
    case CoreAuthentication
    case CoreAuthenticationTests
}

extension CoreModuleName {
    static let targets: [Target] = [
        .module(
            name: CoreModuleName.CoreAuthentication.rawValue,
            dependencies: [
                .sdk(name: "AuthenticationServices", type: .framework),
                .sdk(name: "Security", type: .framework),
            ],
        ),
        .testModule(
            name: CoreModuleName.CoreAuthenticationTests.rawValue,
            productionTarget: .target(
                name: CoreModuleName.CoreAuthentication.rawValue
            ),
        ),
    ]
}

extension TargetDependency {
    static func fromCore(_ name: CoreModuleName) -> Self {
        .project(target: name.rawValue, path: "../Core")
    }
}
