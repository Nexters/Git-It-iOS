import ProjectDescription

// MARK: - ProjectName

public enum ProjectName: String, CaseIterable {
    case App
    case DI
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
            case .DI:
                DIModuleName.targets
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
        let options: Project.Options =
            self == .App
                ? .options(automaticSchemesOptions: .disabled)
                : .options()
        let schemes: [Scheme] =
            self == .App
                ? AppModuleName.schemes
                : []

        return Project(
            name: rawValue,
            organizationName: "Nexters",
            options: options,
            targets: targets,
            schemes: schemes,
        )
    }
}
