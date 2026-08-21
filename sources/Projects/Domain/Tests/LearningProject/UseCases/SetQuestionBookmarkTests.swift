import Testing

@testable import DomainLearningProject

// MARK: - SetQuestionBookmarkTests

@Suite("SetQuestionBookmark")
struct SetQuestionBookmarkTests {
    @Test
    func `desired bool을 정확히 전송한다`() async throws {
        let repository = SetQuestionBookmarkRepository()
        let setQuestionBookmark = SetQuestionBookmark(repository: repository)

        _ = try await setQuestionBookmark(projectID: "project-1", questionID: "q1", bookmarked: true)

        #expect(await repository.lastRequestedValue == true)
    }

    @Test
    func `서버 최종 응답을 정본으로 반영한다`() async throws {
        let repository = SetQuestionBookmarkRepository(responds: false)
        let setQuestionBookmark = SetQuestionBookmark(repository: repository)

        let state = try await setQuestionBookmark(projectID: "project-1", questionID: "q1", bookmarked: true)

        #expect(state.bookmarked == false)
    }

    @Test
    func `같은 question의 동시 호출은 직렬화된다`() async throws {
        let repository = SetQuestionBookmarkRepository()
        let setQuestionBookmark = SetQuestionBookmark(repository: repository)

        async let first = setQuestionBookmark(projectID: "project-1", questionID: "q1", bookmarked: true)
        async let second = setQuestionBookmark(projectID: "project-1", questionID: "q1", bookmarked: false)
        _ = try await (first, second)

        #expect(await repository.maxConcurrentCalls == 1)
    }
}

// MARK: - SetQuestionBookmarkRepository

private actor SetQuestionBookmarkRepository: BookmarkRepository {

    // MARK: Lifecycle

    init(responds: Bool? = nil) {
        self.responds = responds
    }

    // MARK: Internal

    private(set) var lastRequestedValue: Bool?
    private(set) var maxConcurrentCalls = 0

    func setBookmark(
        projectID _: String,
        questionID _: String,
        bookmarked: Bool,
    ) async throws -> BookmarkState {
        lastRequestedValue = bookmarked
        concurrentCalls += 1
        maxConcurrentCalls = max(maxConcurrentCalls, concurrentCalls)
        try? await Task.sleep(nanoseconds: 5_000_000)
        concurrentCalls -= 1
        return BookmarkState(bookmarked: responds ?? bookmarked)
    }

    func fetchBookmarkedQuestions(projectID _: String?) async throws -> BookmarkedQuestionCollection {
        BookmarkedQuestionCollection(totalCount: 0, availableProjects: [], bookmarks: [])
    }

    // MARK: Private

    private let responds: Bool?
    private var concurrentCalls = 0

}
