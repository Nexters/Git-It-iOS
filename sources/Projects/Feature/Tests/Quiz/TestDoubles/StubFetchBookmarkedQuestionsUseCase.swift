import DomainLearningProject

actor StubFetchBookmarkedQuestionsUseCase: FetchBookmarkedQuestionsUseCase {

    // MARK: Lifecycle

    init(results: [Result<BookmarkedQuestionCollection, LearningProjectError>] = [.failure(.unexpected)]) {
        self.results = results
    }

    // MARK: Internal

    private(set) var callCount = 0
    private(set) var requestedProjectIDs = [String?]()

    func callAsFunction(projectID: String?) async throws -> BookmarkedQuestionCollection {
        callCount += 1
        requestedProjectIDs.append(projectID)
        return try nextResult().get()
    }

    // MARK: Private

    private var results: [Result<BookmarkedQuestionCollection, LearningProjectError>]

    private func nextResult() -> Result<BookmarkedQuestionCollection, LearningProjectError> {
        guard !results.isEmpty else { return .failure(.unexpected) }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
