public protocol SetQuestionBookmarkUseCase: Sendable {
    func callAsFunction(
        projectID: String,
        questionID: String,
        bookmarked: Bool,
    ) async throws -> BookmarkState
}
