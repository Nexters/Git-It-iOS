public protocol LoginSessionRemote: Sendable {
    func startSession(_ request: LoginSessionStartRequestDTO) async throws -> LoginSessionResponseDTO
    func refreshSession(_ request: RefreshRequestDTO) async throws -> RefreshResponseDTO
    func revokeRefreshToken(_ refreshToken: String) async throws
}
