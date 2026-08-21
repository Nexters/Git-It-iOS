public enum SessionRefreshOutcome: Equatable, Sendable {
    case refreshed(SessionTokens)
    case rejected
    case temporarilyUnavailable
}
