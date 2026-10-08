extension SignInFeature {
    public enum Phase: Equatable, Sendable {
        case idle
        case checkingConsent
        case agreeingToPolicies
        case signingIn
        case cancelled
        case failed
    }
}
