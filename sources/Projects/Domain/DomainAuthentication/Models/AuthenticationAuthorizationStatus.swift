public enum AuthenticationAuthorizationStatus: CaseIterable, Equatable, Sendable {
    case authorized
    case reauthenticationRequired
    case temporarilyUnavailable
}
