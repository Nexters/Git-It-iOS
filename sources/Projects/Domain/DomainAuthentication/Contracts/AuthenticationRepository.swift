public protocol AuthenticationRepository: Sendable {
    func authenticate(using method: AuthenticationMethod) async throws -> AuthenticationGrant
    func authorizationStatus() async throws -> AuthenticationAuthorizationStatus
    func authorizationChanges() async -> AsyncStream<AuthenticationAuthorizationStatus>
    func clearAuthorization() async throws
}
