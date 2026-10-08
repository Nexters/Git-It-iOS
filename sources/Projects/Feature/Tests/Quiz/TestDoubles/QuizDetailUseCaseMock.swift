import DomainIdentifier
import DomainQuizDetail

actor QuizDetailUseCaseMock: QuizDetailUseCase {

    // MARK: Lifecycle

    init(
        quizSetResults: [Result<QuizSet, QuizDetailError>] = [.failure(.unexpected)],
        choiceGradingResults: [Result<ChoiceGrading, QuizDetailError>] = [.failure(.unexpected)],
        essayGradingResults: [Result<EssayGrading, QuizDetailError>] = [.failure(.unexpected)],
        bookmarkStateResults: [Result<QuizBookmarkState, QuizDetailError>] = [.failure(.unexpected)],
        bookmarkListResults: [Result<QuizBookmarkList, QuizDetailError>] = [.failure(.unexpected)],
    ) {
        self.quizSetResults = quizSetResults
        self.choiceGradingResults = choiceGradingResults
        self.essayGradingResults = essayGradingResults
        self.bookmarkStateResults = bookmarkStateResults
        self.bookmarkListResults = bookmarkListResults
    }

    // MARK: Internal

    struct BookmarkInvocation: Equatable, Sendable {
        let quizID: QuizID
        let projectID: ProjectID
        let isBookmarked: Bool
    }

    private(set) var requestedSetIDs = [QuizSetID]()
    private(set) var requestedBookmarkFilters = [QuizBookmarkFilter]()
    private(set) var choiceAnswers = [ChoiceAnswer]()
    private(set) var essayAnswers = [EssayAnswer]()
    private(set) var bookmarkInvocations = [BookmarkInvocation]()

    func quizSet(
        _ setID: QuizSetID,
        in _: ProjectID,
    ) async throws -> QuizSet {
        requestedSetIDs.append(setID)
        return try Self.next(&quizSetResults).get()
    }

    func grade(_ answer: ChoiceAnswer) async throws -> ChoiceGrading {
        choiceAnswers.append(answer)
        return try Self.next(&choiceGradingResults).get()
    }

    func grade(_ answer: EssayAnswer) async throws -> EssayGrading {
        essayAnswers.append(answer)
        return try Self.next(&essayGradingResults).get()
    }

    func bookmark(
        _ quizID: QuizID,
        in projectID: ProjectID,
    ) async throws -> QuizBookmarkState {
        bookmarkInvocations.append(
            BookmarkInvocation(
                quizID: quizID,
                projectID: projectID,
                isBookmarked: true,
            )
        )
        return try Self.next(&bookmarkStateResults).get()
    }

    func unbookmark(
        _ quizID: QuizID,
        in projectID: ProjectID,
    ) async throws -> QuizBookmarkState {
        bookmarkInvocations.append(
            BookmarkInvocation(
                quizID: quizID,
                projectID: projectID,
                isBookmarked: false,
            )
        )
        return try Self.next(&bookmarkStateResults).get()
    }

    func bookmarks(_ filter: QuizBookmarkFilter) async throws -> QuizBookmarkList {
        requestedBookmarkFilters.append(filter)
        return try Self.next(&bookmarkListResults).get()
    }

    // MARK: Private

    private var quizSetResults: [Result<QuizSet, QuizDetailError>]
    private var choiceGradingResults: [Result<ChoiceGrading, QuizDetailError>]
    private var essayGradingResults: [Result<EssayGrading, QuizDetailError>]
    private var bookmarkStateResults: [Result<QuizBookmarkState, QuizDetailError>]
    private var bookmarkListResults: [Result<QuizBookmarkList, QuizDetailError>]

    private static func next<Value>(
        _ results: inout [Result<Value, QuizDetailError>]
    ) -> Result<Value, QuizDetailError> {
        guard !results.isEmpty else { return .failure(.unexpected) }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
