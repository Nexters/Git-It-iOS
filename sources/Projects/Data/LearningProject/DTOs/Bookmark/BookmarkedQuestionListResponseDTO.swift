public struct BookmarkedQuestionListResponseDTO: Decodable, Equatable, Sendable {
    public init(
        totalCount: Int,
        availableProjects: [AvailableProjectResponseDTO],
        bookmarks: [BookmarkedQuestionResponseDTO],
    ) {
        self.totalCount = totalCount
        self.availableProjects = availableProjects
        self.bookmarks = bookmarks
    }

    public let totalCount: Int
    public let availableProjects: [AvailableProjectResponseDTO]
    public let bookmarks: [BookmarkedQuestionResponseDTO]
}
