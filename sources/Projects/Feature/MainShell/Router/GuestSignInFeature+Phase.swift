extension GuestSignInFeature {
    public enum Phase: Equatable, Sendable {
        case idle
        case checkingConsent
        case agreeingToPolicies
        case signingIn
        case failed
    }
}
