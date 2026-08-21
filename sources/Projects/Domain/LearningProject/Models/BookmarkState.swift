/// UC09 응답의 최종 정본. 서버가 돌려준 bool만 정본이며 클라이언트의 낙관적 값이 아니다.
public struct BookmarkState: Equatable, Sendable {

    // MARK: Lifecycle

    public init(bookmarked: Bool) {
        self.bookmarked = bookmarked
    }

    // MARK: Public

    public let bookmarked: Bool

}
