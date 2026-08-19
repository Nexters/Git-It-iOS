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
                [.package(
                    name: self,
                    buildTargets: [
                        AppModuleName.GitIt.rawValue
                    ],
                    testTargets: [
                        AppModuleName.GitItTests.rawValue
                    ],
                    runTarget: AppModuleName.GitIt.rawValue,
                    supportsDistribution: true,
                )]

            case .Composition:
                [.package(
                    name: self,
                    buildTargets: [
                        CompositionModuleName.CompositionAdepter.rawValue
                    ],
                    testTargets: [
                        CompositionModuleName.CompositionAdepterTests.rawValue
                    ],
                )]

            case .Feature:
                [.package(
                    name: self,
                    buildTargets: [
                        FeatureModuleName.Feature.rawValue
                    ],
                    testTargets: [
                        FeatureModuleName.FeatureTests.rawValue
                    ],
                )]

            case .Domain:
                [.package(
                    name: self,
                    buildTargets: [
                        DomainModuleName.DomainAuthentication.rawValue,
                        DomainModuleName.DomainLearningProject.rawValue,
                    ],
                    testTargets: [
                        DomainModuleName.DomainAuthenticationTests.rawValue,
                        DomainModuleName.DomainLearningProjectTests.rawValue,
                    ],
                )]

            case .Data:
                [.package(
                    name: self,
                    buildTargets: [
                        DataModuleName.DataAuthentication.rawValue,
                        DataModuleName.DataLearningProject.rawValue,
                    ],
                    testTargets: [
                        DataModuleName.DataAuthenticationTests.rawValue,
                        DataModuleName.DataLearningProjectTests.rawValue,
                    ],
                )]

            case .Infrastructure:
                [.package(
                    name: self,
                    buildTargets: [
                        InfrastructureModuleName.InfrastructureAuthentication.rawValue,
                        InfrastructureModuleName.InfrastructureNetworkClient.rawValue,
                        InfrastructureModuleName.InfrastructureCache.rawValue,
                    ],
                    testTargets: [
                        InfrastructureModuleName.InfrastructureAuthenticationTests.rawValue,
                        InfrastructureModuleName.InfrastructureNetworkClientTests.rawValue,
                        InfrastructureModuleName.InfrastructureCacheTests.rawValue,
                    ],
                )]

            case .UI:
                [.package(
                    name: self,
                    buildTargets: [
                        UIModuleName.DesignSystem.rawValue,
                        UIModuleName.UIComponent.rawValue,
                        UIModuleName.UIComponentLayoutHarness.rawValue,
                    ],
                    testTargets: [
                        UIModuleName.DesignSystemTests.rawValue,
                        UIModuleName.UIComponentTests.rawValue,
                        UIModuleName.UIComponentUITests.rawValue,
                    ],
                    runTarget: UIModuleName.UIComponentLayoutHarness.rawValue,
                )]
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
        name: ProjectName,
        buildTargets: [String],
        testTargets: [String],
        runTarget: String? = nil,
        supportsDistribution: Bool = false,
    ) -> Self {
        .scheme(
            name: name.rawValue,
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
            profileAction: supportsDistribution ? runTarget.map {
                .profileAction(executable: .executable(.target($0)))
            } : nil,
            analyzeAction: supportsDistribution
                ? .analyzeAction(configuration: .debug)
                : nil,
        )
    }
}
