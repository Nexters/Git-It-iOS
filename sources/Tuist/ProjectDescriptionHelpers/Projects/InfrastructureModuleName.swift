import ProjectDescription

// MARK: - InfrastructureModuleName

enum InfrastructureModuleName: String {
    case InfrastructureAuthentication
    case InfrastructureAuthenticationTests
    case InfrastructureNetworkClient
    case InfrastructureNetworkClientTests
    case InfrastructureCache
    case InfrastructureCacheTests
}

extension InfrastructureModuleName {
    static let targets: [Target] = [
        .module(
            name: InfrastructureModuleName.InfrastructureAuthentication.rawValue,
            sourceDirectory: "Authentication",
            dependencies: [
                .sdk(name: "AuthenticationServices", type: .framework),
                .sdk(name: "Security", type: .framework),
            ],
        ),
        .testModule(
            name: InfrastructureModuleName.InfrastructureAuthenticationTests.rawValue,
            sourceDirectory: "AuthenticationTests",
            productionTarget: .target(
                name: InfrastructureModuleName.InfrastructureAuthentication.rawValue
            ),
        ),
        .module(
            name: InfrastructureModuleName.InfrastructureNetworkClient.rawValue,
            sourceDirectory: "NetworkClient",
            dependencies: [],
        ),
        .testModule(
            name: InfrastructureModuleName.InfrastructureNetworkClientTests.rawValue,
            sourceDirectory: "NetworkClientTests",
            productionTarget: .target(
                name: InfrastructureModuleName.InfrastructureNetworkClient.rawValue
            ),
        ),
        .module(
            name: InfrastructureModuleName.InfrastructureCache.rawValue,
            sourceDirectory: "Cache",
            dependencies: [],
        ),
        .testModule(
            name: InfrastructureModuleName.InfrastructureCacheTests.rawValue,
            sourceDirectory: "CacheTests",
            productionTarget: .target(
                name: InfrastructureModuleName.InfrastructureCache.rawValue
            ),
        ),
    ]
}

extension TargetDependency {
    static func fromInfrastructure(_ name: InfrastructureModuleName) -> Self {
        .project(
            target: name.rawValue,
            path: "../Infrastructure"
        )
    }
}
