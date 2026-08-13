import ProjectDescription

// MARK: - ProjectName

public enum ProjectName: String, CaseIterable {
    case App
    case Composition
    case Feature
    case Domain
    case Data
    case Core
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
            case .Core:
                CoreModuleName.targets
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
                [.module(
                    name: "DomainAuthentication",
                    testTarget: "DomainAuthenticationTests",
                )]

            case .Data:
                [.module(
                    name: "DataAuthentication",
                    testTarget: "DataAuthenticationTests",
                )]

            case .Core:
                [.module(
                    name: "CoreAuthentication",
                    testTarget: "CoreAuthenticationTests",
                )]

            case .UI:
                [
                    .module(name: "DesignSystem"),
                    .module(name: "UIComponent"),
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
