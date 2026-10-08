public struct BookmarkQuestionResponseDTO: Decodable, Equatable, Sendable {
    public init(bookmarked: Bool) {
        self.bookmarked = bookmarked
    }

    public let bookmarked: Bool
}
