/// UC10 응답. `availableProjects`는 filter와 무관하게 항상 전체 목록을 유지한다
/// (filter 결과로 재계산하지 않는다).
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
