public protocol SignInRepository: Sendable {
    func start(with grant: AuthenticationGrant) async throws -> SignInRecord
    func restore() async throws -> SignInRecord?
    func signOut() async throws
    func sharedSignInState() async -> Bool?
    func hasUsableCredential() async -> Bool
}
