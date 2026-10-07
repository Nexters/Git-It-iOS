public struct BookmarkedQuestionCollection: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        totalCount: Int,
        availableProjects: [BookmarkedProject],
        bookmarks: [BookmarkedQuestion],
    ) {
        self.totalCount = totalCount
        self.availableProjects = availableProjects
        self.bookmarks = bookmarks
    }

    // MARK: Public

    public let totalCount: Int
    public let availableProjects: [BookmarkedProject]
    public let bookmarks: [BookmarkedQuestion]

}
