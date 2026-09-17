import DomainIdentifier
import Foundation

public actor QuizDetail: QuizDetailUseCase {

    // MARK: Lifecycle

    public init(
        quizSetRepository: any QuizSetRepository,
        answerRepository: any AnswerRepository,
        bookmarkRepository: any BookmarkRepository,
    ) {
        self.quizSetRepository = quizSetRepository
        self.answerRepository = answerRepository
        self.bookmarkRepository = bookmarkRepository
    }

    // MARK: Public

    public func quizSet(
        _ setID: QuizSetID,
        in projectID: ProjectID,
    ) async throws -> QuizSet {
        try await quizSetRepository.quizSet(setID, in: projectID)
    }

    public func grade(_ answer: ChoiceAnswer) async throws -> ChoiceGrading {
        guard answer.selectedIndex >= 0 else {
            throw QuizDetailError.invalidAnswer
        }
        return try await answerRepository.submit(answer)
    }

    public func grade(_ answer: EssayAnswer) async throws -> EssayGrading {
        let trimmed = answer.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= Self.maximumEssayLength else {
            throw QuizDetailError.invalidAnswer
        }
        return try await answerRepository.submit(
            EssayAnswer(projectID: answer.projectID, quizID: answer.quizID, text: trimmed)
        )
    }

    public func bookmark(
        _ quizID: QuizID,
        in projectID: ProjectID,
    ) async throws -> QuizBookmarkState {
        try await setBookmark(quizID, in: projectID, isBookmarked: true)
    }

    public func unbookmark(
        _ quizID: QuizID,
        in projectID: ProjectID,
    ) async throws -> QuizBookmarkState {
        try await setBookmark(quizID, in: projectID, isBookmarked: false)
    }

    public func bookmarks(_ filter: QuizBookmarkFilter) async throws -> QuizBookmarkList {
        try await bookmarkRepository.bookmarks(filter)
    }

    // MARK: Internal

    var pendingBookmarkCount: Int {
        inFlight.count
    }

    // MARK: Private

    private struct PendingMutation {
        let token: UUID
        let awaitCompletion: @Sendable () async -> Void
    }

    private static let maximumEssayLength = 2000

    private let quizSetRepository: any QuizSetRepository
    private let answerRepository: any AnswerRepository
    private let bookmarkRepository: any BookmarkRepository

    private var inFlight = [QuizID: PendingMutation]()

    private func setBookmark(
        _ quizID: QuizID,
        in projectID: ProjectID,
        isBookmarked: Bool,
    ) async throws -> QuizBookmarkState {
        let bookmarkRepository = bookmarkRepository
        let token = UUID()
        let previous = inFlight[quizID]

        let task = Task<QuizBookmarkState, Error> {
            await previous?.awaitCompletion()
            return try await bookmarkRepository.setBookmark(quizID, in: projectID, isBookmarked: isBookmarked)
        }
        inFlight[quizID] = PendingMutation(token: token, awaitCompletion: { _ = try? await task.value })

        defer {
            if inFlight[quizID]?.token == token {
                inFlight[quizID] = nil
            }
        }

        return try await task.value
    }

}
