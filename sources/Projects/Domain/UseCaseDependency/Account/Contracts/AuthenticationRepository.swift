import DomainUseCaseInterface

public protocol AuthenticationRepository: Sendable {
    func authenticate(using method: SignInMethod) async throws -> AuthenticationGrant
    func authorizationStatus() async throws -> SignInVerification
    func clearAuthentication() async throws
}
