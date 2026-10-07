public enum SignInState: Equatable, Sendable {
    case unknown
    case signedIn(AccountID)
    case signedOut
}
