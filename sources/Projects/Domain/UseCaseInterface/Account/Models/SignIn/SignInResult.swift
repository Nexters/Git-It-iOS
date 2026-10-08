public enum SignInResult: Equatable, Sendable {
    case signedIn(SignedInAccount)
    case cancelled
    case retryableFailure
}
