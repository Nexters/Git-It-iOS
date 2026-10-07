public protocol AuthenticationRepository: Sendable {
    func authenticate(using method: AuthenticationMethod) async throws -> AuthenticationGrant
    func authorizationStatus() async throws -> AuthorizationStatus
    func clearAuthentication() async throws
}
