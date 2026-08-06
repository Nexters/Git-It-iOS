import ProjectDescription

enum ExternalDependenciesName: String {
    case ComposableArchitecture
    case FirebaseAnalytics
    case FirebaseCrashlytics
}

extension TargetDependency {
    static func external(_ name: ExternalDependenciesName) -> Self {
        .external(name: name.rawValue)
    }
}
