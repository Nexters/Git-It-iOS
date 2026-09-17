import DomainIdentifier
import DomainProject

actor ProjectUseCaseDeletionStub {

    // MARK: Lifecycle

    init(results: [Result<Void, ProjectError>] = [.success(())]) {
        self.results = results
    }

    // MARK: Internal

    private(set) var callCount = 0
    private(set) var requestedProjectIDs = [ProjectID]()

    nonisolated var deleteProject: @Sendable (ProjectID) async throws -> Void {
        { try await self(projectID: $0) }
    }

    func callAsFunction(projectID: ProjectID) async throws {
        callCount += 1
        requestedProjectIDs.append(projectID)
        try nextResult().get()
    }

    // MARK: Private

    private var results: [Result<Void, ProjectError>]

    private func nextResult() -> Result<Void, ProjectError> {
        guard !results.isEmpty else { return .failure(.unexpected) }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
