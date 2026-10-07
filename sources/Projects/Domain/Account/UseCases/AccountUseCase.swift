public protocol AccountUseCase: Sendable {
    func signIn(with method: SignInMethod) async -> SignInResult
    func signOut() async -> SignOutResult
    func signInStates() async -> AsyncStream<SignInState>
    func restoreSignIn() async -> SignInRestoration
    func verifySignIn() async -> SignInVerification
    func signInAvailability() async -> SignInAvailability
    func policyConsentStatus() async throws -> PolicyConsentStatus
    func consent(to documentIDs: [PolicyDocumentID]) async throws
    func withdraw() async throws
}
