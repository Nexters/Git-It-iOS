import ProjectDescription

// MARK: - CompositionModuleName

enum CompositionModuleName: String, CaseIterable {
    case Composition
}

extension CompositionModuleName {
    var target: Target {
        .module(
            name: rawValue,
            dependencies: [
                .fromDomain(.Domain),
                .fromData(.Data),
                .fromCore(.Utility),
            ],
        )
    }
}

extension TargetDependency {
    static func fromComposition(_ name: CompositionModuleName) -> Self {
        .project(target: name.rawValue, path: "../Composition")
    }
}
