public enum RestoreSessionResult: Equatable, Sendable {
    case authenticated(AuthenticatedUser)
    case unauthenticated
    case recoverableFailure
}
