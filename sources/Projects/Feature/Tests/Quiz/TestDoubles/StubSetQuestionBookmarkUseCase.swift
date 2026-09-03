import DomainLearningProject

actor StubSetQuestionBookmarkUseCase: SetQuestionBookmarkUseCase {

    // MARK: Lifecycle

    init(results: [Result<BookmarkState, LearningProjectError>] = [.failure(.unexpected)]) {
        self.results = results
    }

    // MARK: Internal

    struct Invocation: Equatable, Sendable {
        let projectID: String
        let questionID: String
        let bookmarked: Bool
    }

    private(set) var invocations = [Invocation]()

    func callAsFunction(
        projectID: String,
        questionID: String,
        bookmarked: Bool,
    ) async throws -> BookmarkState {
        invocations.append(
            Invocation(projectID: projectID, questionID: questionID, bookmarked: bookmarked)
        )
        return try nextResult().get()
    }

    // MARK: Private

    private var results: [Result<BookmarkState, LearningProjectError>]

    private func nextResult() -> Result<BookmarkState, LearningProjectError> {
        guard !results.isEmpty else { return .failure(.unexpected) }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
