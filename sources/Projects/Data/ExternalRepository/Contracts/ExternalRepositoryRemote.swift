public protocol ExternalRepositoryRemote: Sendable {
    func repository(_ request: GitHubRepositoryRequest) async throws -> GitHubRepositoryResponseDTO
}
