public protocol BookmarkRepository: Sendable {
    func setBookmark(
        projectID: String,
        questionID: String,
        bookmarked: Bool,
    ) async throws -> BookmarkState

    func fetchBookmarkedQuestions(projectID: String?) async throws -> BookmarkedQuestionCollection
}
