public enum SignInRestoration: Equatable, Sendable {
    case signedIn(SignedInAccount)
    case signedOut
    case temporarilyUnavailable
}
