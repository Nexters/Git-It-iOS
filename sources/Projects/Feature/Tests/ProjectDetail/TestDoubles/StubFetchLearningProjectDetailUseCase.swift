import DomainLearningProject

actor StubFetchLearningProjectDetailUseCase: FetchLearningProjectDetailUseCase {

    // MARK: Lifecycle

    init(results: [Result<LearningProjectDetail, LearningProjectError>] = [.failure(.unexpected)]) {
        self.results = results
    }

    // MARK: Internal

    private(set) var callCount = 0
    private(set) var requestedProjectIDs = [String]()

    func callAsFunction(projectID: String) async throws -> LearningProjectDetail {
        callCount += 1
        requestedProjectIDs.append(projectID)
        return try nextResult().get()
    }

    // MARK: Private

    private var results: [Result<LearningProjectDetail, LearningProjectError>]

    private func nextResult() -> Result<LearningProjectDetail, LearningProjectError> {
        guard !results.isEmpty else { return .failure(.unexpected) }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
