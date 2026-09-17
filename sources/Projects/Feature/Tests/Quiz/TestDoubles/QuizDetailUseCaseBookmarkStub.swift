import DomainIdentifier
import DomainQuizDetail

actor QuizDetailUseCaseBookmarkStub {

    // MARK: Lifecycle

    init(results: [Result<QuizBookmarkState, QuizDetailError>] = [.failure(.unexpected)]) {
        self.results = results
    }

    // MARK: Internal

    struct Invocation: Equatable, Sendable {
        let quizID: QuizID
        let projectID: ProjectID
        let isBookmarked: Bool
    }

    private(set) var invocations = [Invocation]()

    nonisolated var setBookmark: @Sendable (QuizID, ProjectID, Bool) async throws -> QuizBookmarkState {
        { try await self(quizID: $0, projectID: $1, isBookmarked: $2) }
    }

    func callAsFunction(
        quizID: QuizID,
        projectID: ProjectID,
        isBookmarked: Bool,
    ) async throws -> QuizBookmarkState {
        invocations.append(
            Invocation(quizID: quizID, projectID: projectID, isBookmarked: isBookmarked)
        )
        return try nextResult().get()
    }

    // MARK: Private

    private var results: [Result<QuizBookmarkState, QuizDetailError>]

    private func nextResult() -> Result<QuizBookmarkState, QuizDetailError> {
        guard !results.isEmpty else { return .failure(.unexpected) }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
