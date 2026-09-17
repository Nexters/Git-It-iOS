public enum AccountError: CaseIterable, Equatable, Error, Sendable {
    case signInCancelled
    case policyUnavailable
    case withdrawalUnavailable
    case unauthorized
    case temporarilyUnavailable
}
