public enum AppleAuthorizationError: Error, Equatable, Sendable {
    case cancelled
    case invalidCallback
    case expiredAttempt
    case missingCredential
    case unavailable
}
