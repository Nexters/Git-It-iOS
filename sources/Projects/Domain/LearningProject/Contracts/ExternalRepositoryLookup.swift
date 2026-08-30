public protocol ExternalRepositoryLookup: Sendable {
    func repository(
        owner: String,
        name: String,
    ) async throws -> ExternalRepository
}
