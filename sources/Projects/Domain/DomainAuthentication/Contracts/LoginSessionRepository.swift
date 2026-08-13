public protocol LoginSessionRepository: Sendable {
    func start(with grant: AuthenticationGrant) async throws -> AuthenticatedUser
    func restore() async throws -> AuthenticatedUser?
    func signOut() async throws
}
