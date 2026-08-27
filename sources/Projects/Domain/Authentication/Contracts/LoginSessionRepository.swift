public protocol LoginSessionRepository: Sendable {
    func start(with grant: AuthenticationGrant) async throws -> AuthenticatedUser
    func restore() async throws -> AuthenticatedUser?
    func signOut() async throws

    func currentSession() async -> SessionRecord?

    func replaceTokens(_ tokens: SessionTokens) async throws

    func updateOnboarding(_ onboarding: LocalOnboardingState) async throws

    func refresh() async throws -> SessionTokens

    func verifyAccessToken() async throws
}
