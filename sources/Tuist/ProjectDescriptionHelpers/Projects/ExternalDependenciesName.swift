import ProjectDescription

// MARK: - ExternalDependenciesName

enum ExternalDependenciesName: String {
    case ComposableArchitecture
    case FirebaseAnalytics
    case FirebaseCrashlytics
    case Lottie
}

extension TargetDependency {
    static func external(_ name: ExternalDependenciesName) -> Self {
        .external(name: name.rawValue)
    }
}
