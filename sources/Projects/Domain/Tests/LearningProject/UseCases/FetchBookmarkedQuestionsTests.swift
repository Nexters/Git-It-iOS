import Testing

@testable import DomainLearningProject

// MARK: - FetchBookmarkedQuestionsTests

@Suite("FetchBookmarkedQuestions")
struct FetchBookmarkedQuestionsTests {
    @Test
    func `필터와 무관하게 availableProjects는 전체 목록을 유지한다`() async throws {
        let collection = BookmarkedQuestionCollection(
            totalCount: 3,
            availableProjects: ["project-1", "project-2"],
            bookmarks: [
                BookmarkedQuestion(projectID: "project-1", setID: "set-1", questionID: "q1", prompt: "p1")
            ],
        )
        let repository = FetchBookmarkedQuestionsRepository(behavior: .succeed(collection))
        let fetchBookmarkedQuestions = FetchBookmarkedQuestions(repository: repository)

        let result = try await fetchBookmarkedQuestions(projectID: "project-1")

        #expect(result.availableProjects == ["project-1", "project-2"])
    }

    @Test
    func `route 식별자를 완전하게 보존한다`() async throws {
        let bookmark = BookmarkedQuestion(projectID: "project-1", setID: "set-1", questionID: "q1", prompt: "p1")
        let collection = BookmarkedQuestionCollection(totalCount: 1, availableProjects: ["project-1"], bookmarks: [bookmark])
        let repository = FetchBookmarkedQuestionsRepository(behavior: .succeed(collection))
        let fetchBookmarkedQuestions = FetchBookmarkedQuestions(repository: repository)

        let result = try await fetchBookmarkedQuestions(projectID: nil)

        #expect(result.bookmarks.first?.projectID == "project-1")
        #expect(result.bookmarks.first?.setID == "set-1")
        #expect(result.bookmarks.first?.questionID == "q1")
    }
}

// MARK: - FetchBookmarkedQuestionsRepository

private struct FetchBookmarkedQuestionsRepository: BookmarkRepository {
    enum Behavior: Sendable {
        case succeed(BookmarkedQuestionCollection)
    }

    let behavior: Behavior

    func setBookmark(
        projectID _: String,
        questionID _: String,
        bookmarked: Bool,
    ) async throws -> BookmarkState {
        BookmarkState(bookmarked: bookmarked)
    }

    func fetchBookmarkedQuestions(projectID _: String?) async throws -> BookmarkedQuestionCollection {
        switch behavior {
        case .succeed(let collection):
            collection
        }
    }
}
