import ProjectDescription

// MARK: - ExternalDependenciesName

enum ExternalDependenciesName: String {
    case ComposableArchitecture
    case Dependencies
    case FirebaseAnalytics
    case FirebaseCrashlytics
}

extension TargetDependency {
    static func external(_ name: ExternalDependenciesName) -> Self {
        .external(name: name.rawValue)
    }
}
