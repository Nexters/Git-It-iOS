import DomainIdentifier

public protocol ProjectRepository: Sendable {
    func page(
        _ index: Int,
        size: Int,
    ) async throws -> ProjectPage
    func detail(of projectID: ProjectID) async throws -> ProjectDetail
    func delete(_ projectID: ProjectID) async throws
}
