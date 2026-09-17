import DomainIdentifier
import DomainProject

actor StubFetchLearningProjectDetailUseCase: ProjectUseCase {

    // MARK: Lifecycle

    init(results: [Result<ProjectDetail, ProjectError>] = [.failure(.unexpected)]) {
        self.results = results
    }

    // MARK: Internal

    private(set) var callCount = 0
    private(set) var requestedProjectIDs = [ProjectID]()
    private(set) var deletedProjectIDs = [ProjectID]()

    nonisolated var projectDetail: @Sendable (ProjectID) async throws -> ProjectDetail {
        { try await self(projectID: $0) }
    }

    func callAsFunction(projectID: ProjectID) async throws -> ProjectDetail {
        callCount += 1
        requestedProjectIDs.append(projectID)
        return try nextResult().get()
    }

    func projects() async -> AsyncStream<ProjectList> {
        AsyncStream { $0.finish() }
    }

    func refresh() async throws { }

    func requestNextPage() async throws { }

    func detail(of projectID: ProjectID) async throws -> ProjectDetail {
        try await self(projectID: projectID)
    }

    func delete(_ projectID: ProjectID) async throws {
        deletedProjectIDs.append(projectID)
    }

    // MARK: Private

    private var results: [Result<ProjectDetail, ProjectError>]

    private func nextResult() -> Result<ProjectDetail, ProjectError> {
        guard !results.isEmpty else { return .failure(.unexpected) }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
