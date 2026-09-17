public enum SignInAvailability: CaseIterable, Equatable, Sendable {
    case signedIn
    case signInRequired
    case appLaunchRequired
}
