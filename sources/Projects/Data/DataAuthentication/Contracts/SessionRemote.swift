public protocol SessionRemote: Sendable {
    func startSession(_ request: SessionStartRequestDTO) async throws -> SessionResponseDTO
    func refreshSession(_ request: RefreshRequestDTO) async throws -> RefreshResponseDTO
    func revokeRefreshToken(_ refreshToken: String) async throws
}
