public protocol BookmarkRemote: Sendable {
    func setBookmark(
        projectID: String,
        questionID: String,
        request: BookmarkQuestionRequestDTO,
    ) async throws -> BookmarkQuestionResponseDTO
    func fetchBookmarks(projectID: String?) async throws -> BookmarkedQuestionListResponseDTO
}
