import ProjectDescription

// MARK: - ExternalDependenciesName

enum ExternalDependenciesName: String {
    case ComposableArchitecture
    case FirebaseAnalytics
    case FirebaseCore
    case FirebaseCrashlytics
    case FirebaseMessaging
    case Lottie
}

extension TargetDependency {
    static func external(_ name: ExternalDependenciesName) -> Self {
        .external(name: name.rawValue)
    }
}
