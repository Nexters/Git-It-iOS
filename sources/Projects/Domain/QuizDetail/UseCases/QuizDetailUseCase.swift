import DomainIdentifier

public protocol QuizDetailUseCase: Sendable {
    func quizSet(
        _ setID: QuizSetID,
        in projectID: ProjectID,
    ) async throws -> QuizSet
    func grade(_ answer: ChoiceAnswer) async throws -> ChoiceGrading
    func grade(_ answer: EssayAnswer) async throws -> EssayGrading
    func bookmark(
        _ quizID: QuizID,
        in projectID: ProjectID,
    ) async throws -> QuizBookmarkState
    func unbookmark(
        _ quizID: QuizID,
        in projectID: ProjectID,
    ) async throws -> QuizBookmarkState
    func bookmarks(_ filter: QuizBookmarkFilter) async throws -> QuizBookmarkList
}
