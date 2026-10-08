public enum SignOutResult: CaseIterable, Equatable, Sendable {
    case signedOut
    case retryableFailure
}
