import DomainLearningProject

actor StubDeleteLearningProjectUseCase {

    // MARK: Lifecycle

    init(results: [Result<Void, LearningProjectError>] = [.success(())]) {
        self.results = results
    }

    // MARK: Internal

    private(set) var callCount = 0
    private(set) var requestedProjectIDs = [String]()

    nonisolated var deleteProject: @Sendable (String) async throws -> Void {
        { try await self(projectID: $0) }
    }

    func callAsFunction(projectID: String) async throws {
        callCount += 1
        requestedProjectIDs.append(projectID)
        try nextResult().get()
    }

    // MARK: Private

    private var results: [Result<Void, LearningProjectError>]

    private func nextResult() -> Result<Void, LearningProjectError> {
        guard !results.isEmpty else { return .failure(.unexpected) }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
