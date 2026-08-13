public enum AuthenticationError: CaseIterable, Equatable, Error, Sendable {
    case cancelled
    case temporarilyUnavailable
}
