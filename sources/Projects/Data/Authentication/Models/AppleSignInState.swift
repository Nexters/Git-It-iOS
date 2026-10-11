// MARK: - AppleSignInState

public enum AppleSignInState: Equatable, Sendable {
    case authorized
    case reauthenticationRequired
    case temporarilyUnavailable
}
