import ProjectDescription

extension ProjectName {

    // MARK: Public

    public static var allTestsScheme: Scheme {
        .scheme(
            name: "AllTests",
            shared: true,
            buildAction: .buildAction(targets: allTestTargets),
            testAction: .targets(allTestTargets.map {
                .testableTarget(target: $0)
            }),
        )
    }

    // MARK: Private

    private static var allTestTargets: [TargetReference] {
        [
            .project(path: ProjectName.App.projectPath, target: AppModuleName.GitItTests.rawValue),
            .project(path: ProjectName.Composition.projectPath, target: CompositionModuleName.CompositionAdapterTests.rawValue),
            .project(path: ProjectName.Feature.projectPath, target: FeatureModuleName.FeatureTests.rawValue),
            .project(path: ProjectName.Domain.projectPath, target: DomainModuleName.DomainAuthenticationTests.rawValue),
            .project(path: ProjectName.Domain.projectPath, target: DomainModuleName.DomainLearningProjectTests.rawValue),
            .project(path: ProjectName.Domain.projectPath, target: DomainModuleName.DomainMemberTests.rawValue),
            .project(path: ProjectName.Data.projectPath, target: DataModuleName.DataAuthenticationTests.rawValue),
            .project(path: ProjectName.Data.projectPath, target: DataModuleName.DataExternalRepositoryTests.rawValue),
            .project(path: ProjectName.Data.projectPath, target: DataModuleName.DataLearningProjectTests.rawValue),
            .project(path: ProjectName.Data.projectPath, target: DataModuleName.DataLegalConsentTests.rawValue),
            .project(path: ProjectName.Data.projectPath, target: DataModuleName.DataMemberTests.rawValue),
            .project(
                path: ProjectName.Infrastructure.projectPath,
                target: InfrastructureModuleName.InfrastructureAuthenticationTests.rawValue,
            ),
            .project(
                path: ProjectName.Infrastructure.projectPath,
                target: InfrastructureModuleName.InfrastructureNetworkClientTests.rawValue,
            ),
            .project(
                path: ProjectName.Infrastructure.projectPath,
                target: InfrastructureModuleName.InfrastructureCacheTests.rawValue,
            ),
            .project(
                path: ProjectName.Infrastructure.projectPath,
                target: InfrastructureModuleName.InfrastructureStorageTests.rawValue,
            ),
            .project(path: ProjectName.UI.projectPath, target: UIModuleName.UIComponentTests.rawValue),
            .project(path: ProjectName.UI.projectPath, target: UIModuleName.DesignSystemTests.rawValue),
        ]
    }

}
