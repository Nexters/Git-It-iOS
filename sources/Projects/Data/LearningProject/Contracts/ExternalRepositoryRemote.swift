public protocol ExternalRepositoryRemote: Sendable {
    func repository(
        owner: String,
        name: String,
    ) async throws -> GitHubRepositoryResponseDTO
}
