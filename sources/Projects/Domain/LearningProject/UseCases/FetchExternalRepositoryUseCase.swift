public protocol FetchExternalRepositoryUseCase: Sendable {
    func callAsFunction(url: String) async throws -> ExternalRepository
}
