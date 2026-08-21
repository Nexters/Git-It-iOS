import ProjectDescription

extension Target {
    static func module(
        name: String,
        sourceDirectory: String,
        resources: ResourceFileElements? = nil,
        dependencies: [TargetDependency] = [],
        buildLibraryForDistribution: Bool = true,
        definesModule: Bool = true,
    ) -> Self {
        .target(
            name: name,
            destinations: .iOS,
            product: .framework,
            bundleId: "com.nexters.hytime.gitit.\(name.lowercased())",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .default,
            sources: ["\(sourceDirectory)/**"],
            resources: resources,
            dependencies: dependencies,
            settings: .settings(
                base: [
                    "BUILD_LIBRARY_FOR_DISTRIBUTION": buildLibraryForDistribution ? "YES" : "NO",
                    "CODE_SIGN_STYLE": "Automatic",
                    "DEVELOPMENT_TEAM": "6924CABL23",
                    "DEFINES_MODULE": definesModule ? "YES" : "NO",
                    "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                    "SKIP_INSTALL": "YES",
                    "SWIFT_VERSION": "5.0",
                ]
            ),
        )
    }

    static func internalStaticModule(
        name: String,
        sourceDirectory: String,
        dependencies: [TargetDependency] = [],
    ) -> Self {
        .target(
            name: name,
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.nexters.hytime.gitit.\(name.lowercased())",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .default,
            sources: ["\(sourceDirectory)/**"],
            dependencies: dependencies,
            settings: .settings(
                base: [
                    "BUILD_LIBRARY_FOR_DISTRIBUTION": "NO",
                    "CODE_SIGN_STYLE": "Automatic",
                    "DEVELOPMENT_TEAM": "6924CABL23",
                    "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                    "SKIP_INSTALL": "YES",
                    "SWIFT_VERSION": "5.0",
                ]
            ),
        )
    }

    static func testModule(
        name: String,
        sourceDirectory: String,
        productionTarget: TargetDependency,
        additionalDependencies: [TargetDependency] = [],
    ) -> Self {
        let testSourceDirectory = sourceDirectory.isEmpty
            ? "Tests"
            : "Tests/\(sourceDirectory)"
        return .target(
            name: name,
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.nexters.hytime.gitit.\(name.lowercased())",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .default,
            sources: ["\(testSourceDirectory)/**"],
            dependencies: [productionTarget] + additionalDependencies,
            settings: .settings(
                base: [
                    "CODE_SIGN_STYLE": "Automatic",
                    "DEVELOPMENT_TEAM": "6924CABL23",
                    "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                    "SWIFT_VERSION": "5.0",
                ]
            ),
        )
    }

    static func resourceBundle(
        name: String,
        resources: ResourceFileElements,
    ) -> Self {
        .target(
            name: name,
            destinations: .iOS,
            product: .bundle,
            bundleId: "com.nexters.hytime.gitit.\(name.lowercased())",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .default,
            resources: resources,
            settings: .settings(
                base: [
                    "CODE_SIGN_STYLE": "Automatic",
                    "DEVELOPMENT_TEAM": "6924CABL23",
                    "SKIP_INSTALL": "YES",
                ]
            ),
        )
    }

    static func testModule(
        name: String,
        sourceDirectory: String,
        dependencies: [TargetDependency] = [],
    ) -> Self {
        .target(
            name: name,
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.nexters.hytime.gitit.\(name.lowercased())",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .default,
            sources: ["\(sourceDirectory)/**"],
            dependencies: dependencies,
            settings: .settings(
                base: [
                    "CODE_SIGN_STYLE": "Automatic",
                    "DEVELOPMENT_TEAM": "6924CABL23",
                    "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                    "SWIFT_VERSION": "5.0",
                ]
            ),
        )
    }
}
