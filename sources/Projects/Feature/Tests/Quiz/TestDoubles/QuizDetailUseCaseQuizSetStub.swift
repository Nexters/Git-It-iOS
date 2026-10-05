import DomainUseCaseInterface

actor QuizDetailUseCaseQuizSetStub {

    // MARK: Lifecycle

    init(results: [Result<QuizSet, QuizDetailError>] = [.failure(.unexpected)]) {
        self.results = results
    }

    // MARK: Internal

    private(set) var callCount = 0
    private(set) var requestedSetIDs = [QuizSetID]()

    nonisolated var fetchQuizSet: @Sendable (QuizSetID, ProjectID) async throws -> QuizSet {
        { try await self(
            setID: $0,
            projectID: $1,
        ) }
    }

    func callAsFunction(
        setID: QuizSetID,
        projectID _: ProjectID,
    ) async throws -> QuizSet {
        callCount += 1
        requestedSetIDs.append(setID)
        return try nextResult().get()
    }

    // MARK: Private

    private var results: [Result<QuizSet, QuizDetailError>]

    private func nextResult() -> Result<QuizSet, QuizDetailError> {
        guard !results.isEmpty else { return .failure(.unexpected) }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
