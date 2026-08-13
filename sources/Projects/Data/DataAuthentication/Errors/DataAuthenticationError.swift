public enum DataAuthenticationError: CaseIterable, Equatable, Error, Sendable {
    case cancelled
    case temporarilyUnavailable
    case storageFailure
    case sessionStartRejected
    case refreshRejectedOrExpired
    case revocationFailure
}
