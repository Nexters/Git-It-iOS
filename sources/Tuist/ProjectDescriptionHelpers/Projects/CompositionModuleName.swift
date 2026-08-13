import ProjectDescription

// MARK: - CompositionModuleName

enum CompositionModuleName: String, CaseIterable {
    case Composition
    case CompositionTests
}

extension CompositionModuleName {
    var target: Target {
        switch self {
        case .Composition:
            .module(
                name: rawValue,
                dependencies: [
                    .fromDomain(.DomainAuthentication),
                    .fromData(.DataAuthentication),
                    .fromCore(.CoreAuthentication),
                ],
            )

        case .CompositionTests:
            .testModule(
                name: rawValue,
                productionTarget: .target(
                    name: CompositionModuleName.Composition.rawValue
                ),
                additionalDependencies: [
                    .fromDomain(.DomainAuthentication),
                    .fromData(.DataAuthentication),
                    .fromCore(.CoreAuthentication),
                ],
            )
        }
    }
}

extension TargetDependency {
    static func fromComposition(_ name: CompositionModuleName) -> Self {
        .project(target: name.rawValue, path: "../Composition")
    }
}
