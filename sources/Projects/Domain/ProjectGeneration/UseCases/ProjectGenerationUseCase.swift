import DomainIdentifier

public protocol ProjectGenerationUseCase: Sendable {
    func request(_ request: ProjectGenerationRequest) async throws -> ProjectGenerationReceipt
    func states() async -> AsyncStream<ProjectGenerationState>
    func synchronize() async
    func release(_ projectID: ProjectID) async
}
