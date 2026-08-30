public enum LoginSessionError: CaseIterable, Equatable, Error, Sendable {
    case temporarilyUnavailable
    case refreshRejectedOrExpired
    case accountUnavailable
    case unauthorized
}
