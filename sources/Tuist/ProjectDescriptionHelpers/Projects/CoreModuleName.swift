import ProjectDescription

// MARK: - CoreModuleName

enum CoreModuleName: String {
    case CoreAuthentication
    case CoreAuthenticationTests
    case CoreHTTP
    case CoreHTTPTests
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
        .module(
            name: CoreModuleName.CoreHTTP.rawValue,
            dependencies: [],
        ),
        .testModule(
            name: CoreModuleName.CoreHTTPTests.rawValue,
            productionTarget: .target(
                name: CoreModuleName.CoreHTTP.rawValue
            ),
        ),
    ]
}

extension TargetDependency {
    static func fromCore(_ name: CoreModuleName) -> Self {
        .project(
            target: name.rawValue,
            path: "../Core"
        )
    }
}
