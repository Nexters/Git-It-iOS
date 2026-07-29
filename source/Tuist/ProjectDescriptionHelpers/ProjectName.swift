import ProjectDescription

public enum ProjectName: String, CaseIterable {
    case Core
    case Domain
    case Data
    case UI
    case Features
    case Utility
    case App
}

public extension ProjectName {
    var projectPath: Path {
        "Projects/\(rawValue)"
    }

    var project: Project {
        let targets: [Target] = switch self {
        case .Core:
            CoreModuleName.allCases.map(\.target)
        case .Domain:
            DomainModuleName.allCases.map(\.target)
        case .Data:
            DataModuleName.allCases.map(\.target)
        case .UI:
            UIModuleName.allCases.map(\.target)
        case .Features:
            FeatureModuleName.allCases.map(\.target)
        case .Utility:
            UtilityModuleName.allCases.map(\.target)
        case .App:
            AppModuleName.allCases.map(\.target)
        }

        return Project(
            name: rawValue,
            organizationName: "Nexters",
            targets: targets
        )
    }
}
