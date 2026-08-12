public protocol ExternalAuthenticationProvider: Sendable {
    func authenticate(methodIdentifier: String) async throws -> ExternalAuthenticationEvidence
    func authorizationState(
        methodIdentifier: String,
        subjectReference: String,
    ) async throws -> ExternalAuthorizationState
    func authorizationChanges(
        methodIdentifier: String,
        subjectReference: String,
    ) async -> AsyncStream<ExternalAuthorizationState>
}
