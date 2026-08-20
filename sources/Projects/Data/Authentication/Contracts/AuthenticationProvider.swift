public protocol AuthenticationProvider: Sendable {
    func authenticate(methodIdentifier: String) async throws -> AuthenticationEvidence
    func authorizationState(
        methodIdentifier: String,
        subjectReference: String,
    ) async throws -> AuthorizationState
    func authorizationChanges(
        methodIdentifier: String,
        subjectReference: String,
    ) async -> AsyncStream<AuthorizationState>
}
