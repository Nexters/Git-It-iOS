public struct BookmarkState: Equatable, Sendable {

    // MARK: Lifecycle

    public init(bookmarked: Bool) {
        self.bookmarked = bookmarked
    }

    // MARK: Public

    public let bookmarked: Bool

}
