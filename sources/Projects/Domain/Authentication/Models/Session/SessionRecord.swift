public struct SessionRecord: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        tokens: SessionTokens,
        onboarding: LocalOnboardingState,
    ) {
        self.tokens = tokens
        self.onboarding = onboarding
    }

    // MARK: Public

    public let tokens: SessionTokens
    public let onboarding: LocalOnboardingState

}
