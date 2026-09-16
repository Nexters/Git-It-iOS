import DomainLearningProject

actor StubFetchLearningSetUseCase {

    // MARK: Lifecycle

    init(results: [Result<LearningSet, LearningProjectError>] = [.failure(.unexpected)]) {
        self.results = results
    }

    // MARK: Internal

    private(set) var callCount = 0
    private(set) var requestedSetIDs = [String]()

    nonisolated var fetchSet: @Sendable (String, String) async throws -> LearningSet {
        { try await self(projectID: $0, setID: $1) }
    }

    func callAsFunction(
        projectID _: String,
        setID: String,
    ) async throws -> LearningSet {
        callCount += 1
        requestedSetIDs.append(setID)
        return try nextResult().get()
    }

    // MARK: Private

    private var results: [Result<LearningSet, LearningProjectError>]

    private func nextResult() -> Result<LearningSet, LearningProjectError> {
        guard !results.isEmpty else { return .failure(.unexpected) }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
