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
    var sourceDirectory: String {
        let directoryName = rawValue.droppingPrefix(ProjectName.Infrastructure.rawValue)
        return switch self {
        case .InfrastructureAuthentication,
             .InfrastructureNetworkClient,
             .InfrastructureCache:
            directoryName
        case .InfrastructureAuthenticationTests,
             .InfrastructureNetworkClientTests,
             .InfrastructureCacheTests:
            "\(directoryName.droppingSuffix("Tests"))"
        }
    }

    static let targets: [Target] = [
        .module(
            name: InfrastructureModuleName.InfrastructureAuthentication.rawValue,
            sourceDirectory: InfrastructureModuleName.InfrastructureAuthentication.sourceDirectory,
            dependencies: [
                .sdk(name: "AuthenticationServices", type: .framework),
                .sdk(name: "Security", type: .framework),
            ],
        ),
        .testModule(
            name: InfrastructureModuleName.InfrastructureAuthenticationTests.rawValue,
            sourceDirectory: InfrastructureModuleName.InfrastructureAuthenticationTests.sourceDirectory,
            productionTarget: .target(
                name: InfrastructureModuleName.InfrastructureAuthentication.rawValue
            ),
        ),
        .module(
            name: InfrastructureModuleName.InfrastructureNetworkClient.rawValue,
            sourceDirectory: InfrastructureModuleName.InfrastructureNetworkClient.sourceDirectory,
            dependencies: [],
        ),
        .testModule(
            name: InfrastructureModuleName.InfrastructureNetworkClientTests.rawValue,
            sourceDirectory: InfrastructureModuleName.InfrastructureNetworkClientTests.sourceDirectory,
            productionTarget: .target(
                name: InfrastructureModuleName.InfrastructureNetworkClient.rawValue
            ),
        ),
        .module(
            name: InfrastructureModuleName.InfrastructureCache.rawValue,
            sourceDirectory: InfrastructureModuleName.InfrastructureCache.sourceDirectory,
            dependencies: [],
        ),
        .testModule(
            name: InfrastructureModuleName.InfrastructureCacheTests.rawValue,
            sourceDirectory: InfrastructureModuleName.InfrastructureCacheTests.sourceDirectory,
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
