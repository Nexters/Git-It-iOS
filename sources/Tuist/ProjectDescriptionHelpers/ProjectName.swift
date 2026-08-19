import ProjectDescription

// MARK: - ProjectName

public enum ProjectName: String, CaseIterable {
    case App
    case Composition
    case Feature
    case Domain
    case Data
    case Infrastructure
    case UI
}

extension ProjectName {
    public var projectPath: Path {
        "Projects/\(rawValue)"
    }

    public var project: Project {
        let targets: [Target] =
            switch self {
            case .App:
                AppModuleName.allCases.map(\.target)
            case .Composition:
                CompositionModuleName.allCases.map(\.target)
            case .Feature:
                FeatureModuleName.allCases.map(\.target)
            case .Domain:
                DomainModuleName.allCases.map(\.target)
            case .Data:
                DataModuleName.allCases.map(\.target)
            case .Infrastructure:
                InfrastructureModuleName.targets
            case .UI:
                UIModuleName.targets
            }
        let options = Project.Options.options(automaticSchemesOptions: .disabled)
        let schemes: [Scheme] =
            switch self {
            case .App:
                AppModuleName.schemes

            case .Composition:
                [.module(name: "Composition")]

            case .Feature:
                [.module(name: "Feature")]

            case .Domain:
                [
                    .module(
                        name: "DomainAuthentication",
                        testTarget: "DomainAuthenticationTests",
                    ),
                    .module(
                        name: "DomainLearningProject",
                        testTarget: "DomainLearningProjectTests",
                    ),
                ]

            case .Data:
                [.module(
                    name: "DataAuthentication",
                    testTarget: "DataAuthenticationTests",
                )]

            case .Infrastructure:
                [
                    .module(
                        name: "InfrastructureAuthentication",
                        testTarget: "InfrastructureAuthenticationTests",
                    ),
                    .module(
                        name: "InfrastructureNetworkClient",
                        testTarget: "InfrastructureNetworkClientTests",
                    ),
                    .module(
                        name: "InfrastructureCache",
                        testTarget: "InfrastructureCacheTests",
                    ),
                ]

            case .UI:
                [
                    .module(
                        name: "DesignSystem",
                        testTarget: "DesignSystemTests",
                    ),
                    .module(
                        name: "UIComponent",
                        testTarget: "UIComponentTests",
                    ),
                    .scheme(
                        name: "UIComponentLayout",
                        shared: true,
                        buildAction: .buildAction(
                            targets: [.target("UIComponentLayoutHarness")]
                        ),
                        testAction: .targets([
                            .testableTarget(target: .target("UIComponentUITests"))
                        ]),
                        runAction: .runAction(
                            executable: .executable(.target("UIComponentLayoutHarness"))
                        ),
                    ),
                ]
            }

        return Project(
            name: rawValue,
            organizationName: "Nexters",
            options: options,
            targets: targets,
            schemes: schemes,
        )
    }
}

extension Scheme {
    fileprivate static func module(
        name: String,
        testTarget: String? = nil,
    ) -> Self {
        .scheme(
            name: name,
            shared: true,
            buildAction: .buildAction(targets: [.target(name)]),
            testAction: testTarget.map {
                .targets([.testableTarget(target: .target($0))])
            },
        )
    }
}
