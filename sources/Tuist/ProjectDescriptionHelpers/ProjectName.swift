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
                [
                    .package(
                        name: rawValue,
                        buildTargets: [
                            AppModuleName.GitIt.rawValue
                        ],
                        testTargets: [],
                        runTarget: AppModuleName.GitIt.rawValue,
                        supportsDistribution: true,
                    ),
                    .package(
                        name: "AppTests",
                        buildTargets: [
                            AppModuleName.GitItTests.rawValue
                        ],
                        testTargets: [
                            AppModuleName.GitItTests.rawValue
                        ],
                    ),
                ]

            case .Composition:
                [.package(
                    name: rawValue,
                    buildTargets: [
                        CompositionModuleName.CompositionAdapter.rawValue,
                        CompositionModuleName.CompositionApp.rawValue,
                        CompositionModuleName.CompositionShareExtension.rawValue,
                    ],
                    testTargets: [
                        CompositionModuleName.CompositionAdapterTests.rawValue,
                        CompositionModuleName.CompositionAppTests.rawValue,
                        CompositionModuleName.CompositionShareExtensionTests.rawValue,
                    ],
                )]

            case .Feature:
                [.package(
                    name: rawValue,
                    buildTargets: [
                        FeatureModuleName.Feature.rawValue
                    ],
                    testTargets: [
                        FeatureModuleName.FeatureTests.rawValue
                    ],
                )]

            case .Domain:
                [.package(
                    name: rawValue,
                    buildTargets: [
                        DomainModuleName.DomainAuthentication.rawValue,
                        DomainModuleName.DomainLearningProject.rawValue,
                        DomainModuleName.DomainMember.rawValue,
                    ],
                    testTargets: [
                        DomainModuleName.DomainAuthenticationTests.rawValue,
                        DomainModuleName.DomainLearningProjectTests.rawValue,
                        DomainModuleName.DomainMemberTests.rawValue,
                    ],
                )]

            case .Data:
                [.package(
                    name: rawValue,
                    buildTargets: [
                        DataModuleName.DataAuthentication.rawValue,
                        DataModuleName.DataLearningProject.rawValue,
                        DataModuleName.DataLegalConsent.rawValue,
                        DataModuleName.DataMember.rawValue,
                        DataModuleName.DataExternalRepository.rawValue,
                    ],
                    testTargets: [
                        DataModuleName.DataAuthenticationTests.rawValue,
                        DataModuleName.DataLearningProjectTests.rawValue,
                        DataModuleName.DataLegalConsentTests.rawValue,
                        DataModuleName.DataMemberTests.rawValue,
                        DataModuleName.DataExternalRepositoryTests.rawValue,
                    ],
                )]

            case .Infrastructure:
                [.package(
                    name: rawValue,
                    buildTargets: [
                        InfrastructureModuleName.InfrastructureAuthentication.rawValue,
                        InfrastructureModuleName.InfrastructureNetworkClient.rawValue,
                        InfrastructureModuleName.InfrastructureCache.rawValue,
                        InfrastructureModuleName.InfrastructureStorage.rawValue,
                        InfrastructureModuleName.InfrastructurePushMessaging.rawValue,
                    ],
                    testTargets: [
                        InfrastructureModuleName.InfrastructureAuthenticationTests.rawValue,
                        InfrastructureModuleName.InfrastructureNetworkClientTests.rawValue,
                        InfrastructureModuleName.InfrastructureCacheTests.rawValue,
                        InfrastructureModuleName.InfrastructureStorageTests.rawValue,
                    ],
                )]

            case .UI:
                [
                    .package(
                        name: rawValue,
                        buildTargets: [
                            UIModuleName.DesignSystem.rawValue,
                            UIModuleName.UIComponent.rawValue,
                        ],
                        testTargets: [
                            UIModuleName.UIComponentTests.rawValue,
                            UIModuleName.DesignSystemTests.rawValue,
                        ],
                    )
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
    fileprivate static func package(
        name: String,
        buildTargets: [String],
        testTargets: [String],
        runTarget: String? = nil,
        supportsDistribution: Bool = false,
    ) -> Self {
        .scheme(
            name: name,
            shared: true,
            buildAction: .buildAction(targets: buildTargets.map {
                .target($0)
            }),
            testAction: .targets(testTargets.map {
                .testableTarget(target: .target($0))
            }),
            runAction: runTarget.map {
                .runAction(executable: .executable(.target($0)))
            },
            archiveAction: supportsDistribution
                ? .archiveAction(configuration: .release)
                : nil,
            profileAction: supportsDistribution
                ? runTarget.map {
                    .profileAction(executable: .executable(.target($0)))
                }
                : nil,
            analyzeAction: supportsDistribution
                ? .analyzeAction(configuration: .debug)
                : nil,
        )
    }
}
