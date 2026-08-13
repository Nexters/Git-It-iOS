public enum AuthenticationOutcome: Equatable, Sendable {
    case authenticated(AuthenticatedUser)
    case unauthenticated
    case recoverableFailure
}
