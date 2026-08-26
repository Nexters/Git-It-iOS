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
        .target(
            name: InfrastructureModuleName.InfrastructureCache.rawValue,
            destinations: .iOS,
            product: .framework,
            bundleId: "com.nexters.hytime.gitit.\(InfrastructureModuleName.InfrastructureCache.rawValue.lowercased())",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .default,
            sources: ["Cache/**", "Storage/**"],
            dependencies: [],
            settings: .settings(
                base: [
                    "BUILD_LIBRARY_FOR_DISTRIBUTION": "YES",
                    "CODE_SIGN_STYLE": "Automatic",
                    "DEVELOPMENT_TEAM": "6924CABL23",
                    "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                    "SKIP_INSTALL": "YES",
                    "SWIFT_VERSION": "5.0",
                ]
            ),
        ),
        .target(
            name: InfrastructureModuleName.InfrastructureCacheTests.rawValue,
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.nexters.hytime.gitit.\(InfrastructureModuleName.InfrastructureCacheTests.rawValue.lowercased())",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .default,
            sources: ["Tests/Cache/**", "Tests/Storage/**"],
            dependencies: [
                .target(name: InfrastructureModuleName.InfrastructureCache.rawValue)
            ],
            settings: .settings(
                base: [
                    "CODE_SIGN_STYLE": "Automatic",
                    "DEVELOPMENT_TEAM": "6924CABL23",
                    "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                    "SWIFT_VERSION": "5.0",
                ]
            ),
        ),
    ]

    var sourceDirectory: String {
        let directoryName = rawValue.droppingPrefix(ProjectName.Infrastructure.rawValue)
        return switch self {
        case .InfrastructureAuthentication,
             .InfrastructureNetworkClient:
            directoryName
        case .InfrastructureAuthenticationTests,
             .InfrastructureNetworkClientTests:
            "\(directoryName.droppingSuffix("Tests"))"
        case .InfrastructureCache,
             .InfrastructureCacheTests:
            ""
        }
    }
}

extension TargetDependency {
    static func fromInfrastructure(_ name: InfrastructureModuleName) -> Self {
        .project(
            target: name.rawValue,
            path: "../Infrastructure",
        )
    }
}
