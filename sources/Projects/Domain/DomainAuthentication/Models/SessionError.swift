public enum SessionError: CaseIterable, Equatable, Error, Sendable {
    case temporarilyUnavailable
    case refreshRejectedOrExpired
    case accountUnavailable
}
