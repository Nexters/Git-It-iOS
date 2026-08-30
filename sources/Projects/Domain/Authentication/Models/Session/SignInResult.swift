public enum SignInResult: Equatable, Sendable {
    case success(AuthenticatedUser, needsCuration: Bool)
    case cancelled
    case retryableFailure
}
