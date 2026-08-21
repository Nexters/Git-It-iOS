public protocol AuthenticationRemote: Sendable {
    func appleLogin(idToken: String) async throws -> LoginResponseDTO
    func verifyAccessToken() async throws
}
