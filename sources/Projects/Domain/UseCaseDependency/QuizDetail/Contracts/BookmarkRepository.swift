import DomainUseCaseInterface

public protocol BookmarkRepository: Sendable {
    func setBookmark(
        _ quizID: QuizID,
        in projectID: ProjectID,
        isBookmarked: Bool,
    ) async throws -> QuizBookmarkState
    func bookmarks(_ filter: QuizBookmarkFilter) async throws -> QuizBookmarkList
}
