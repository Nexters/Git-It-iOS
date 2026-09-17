import DomainIdentifier

public protocol ExternalRepositoryUseCase: Sendable {
    func repository(at url: ExternalRepositoryURL) async throws -> ExternalRepository
}
