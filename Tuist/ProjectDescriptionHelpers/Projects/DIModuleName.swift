import ProjectDescription

// MARK: - DIModuleName

enum DIModuleName: String {
    case DIInterface
    case DILive
}

extension DIModuleName {
    static let targets: [Target] = [
        .module(
            name: DIModuleName.DILive.rawValue,
            dependencies: [
                .target(name: DIModuleName.DIInterface.rawValue),
                .fromDomain(.Domain),
                .fromData(.Data),
                .external(.Dependencies),
            ],
        ),
        .module(
            name: DIModuleName.DIInterface.rawValue,
            dependencies: [
                .fromDomain(.Domain),
                .external(.Dependencies),
            ],
        ),
    ]
}

extension TargetDependency {
    static func fromDI(_ name: DIModuleName) -> Self {
        .project(target: name.rawValue, path: "../DI")
    }
}
