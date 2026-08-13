public enum AuthorizationStatus: CaseIterable, Equatable, Sendable {
    case authorized
    case reauthenticationRequired
    case temporarilyUnavailable
}
