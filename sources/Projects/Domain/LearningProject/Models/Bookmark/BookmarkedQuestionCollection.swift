public struct BookmarkedQuestionCollection: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        totalCount: Int,
        availableProjects: [String],
        bookmarks: [BookmarkedQuestion],
    ) {
        self.totalCount = totalCount
        self.availableProjects = availableProjects
        self.bookmarks = bookmarks
    }

    // MARK: Public

    public let totalCount: Int
    public let availableProjects: [String]
    public let bookmarks: [BookmarkedQuestion]

}
