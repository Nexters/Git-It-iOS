public struct QuizBookmarkList: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        totalCount: Int,
        projects: [QuizBookmarkProject],
        bookmarks: [QuizBookmark],
    ) {
        self.totalCount = totalCount
        self.projects = projects
        self.bookmarks = bookmarks
    }

    // MARK: Public

    public let totalCount: Int
    public let projects: [QuizBookmarkProject]
    public let bookmarks: [QuizBookmark]

}
