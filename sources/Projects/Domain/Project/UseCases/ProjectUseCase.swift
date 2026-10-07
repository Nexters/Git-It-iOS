import DomainIdentifier

public protocol ProjectUseCase: Sendable {
    func projects() async -> AsyncStream<ProjectList>
    func refresh() async throws
    func requestNextPage() async throws
    func detail(of projectID: ProjectID) async throws -> ProjectDetail
    func delete(_ projectID: ProjectID) async throws
}
