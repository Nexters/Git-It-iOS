public enum SignInVerification: CaseIterable, Equatable, Sendable {
    case valid
    case reauthenticationRequired
    case temporarilyUnavailable
}
