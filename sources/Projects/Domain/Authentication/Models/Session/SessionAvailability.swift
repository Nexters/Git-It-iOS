public enum SessionAvailability: Equatable, Sendable {
    case available(accessToken: String)
    case signInRequired
    case appLaunchRequired
}
