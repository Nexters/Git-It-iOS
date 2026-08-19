public enum AuthorizationState: CaseIterable, Equatable, Sendable {
    case active
    case inactive
    case temporarilyUnavailable
}
