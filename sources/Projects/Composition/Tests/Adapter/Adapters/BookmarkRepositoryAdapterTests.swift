import Testing

@testable import CompositionAdapter
@testable import DataLearningProject
@testable import DomainLearningProject

// MARK: - BookmarkRepositoryAdapterTests

@Suite("BookmarkRepositoryAdapter")
struct BookmarkRepositoryAdapterTests {

    @Test
    func `설정 응답 DTO를 서버가 돌려준 bool 정본으로 변환한다`() async throws {
        let remote = StubBookmarkRemote(setResult: .success(BookmarkQuestionResponseDTO(bookmarked: true)))
        let adapter = BookmarkRepositoryAdapter(remote: remote)

        let state = try await adapter.setBookmark(projectID: "project-1", questionID: "question-1", bookmarked: true)

        #expect(state.bookmarked)
    }

    @Test
    func `목록 응답의 availableProjects를 필터와 무관하게 그대로 보존한다`() async throws {
        let remote = StubBookmarkRemote(listResult: .success(BookmarkedQuestionListResponseDTO(
            totalCount: 2,
            availableProjects: [
                AvailableProjectResponseDTO(projectID: "project-1", repositoryName: "repo-1"),
                AvailableProjectResponseDTO(projectID: "project-2", repositoryName: "repo-2"),
            ],
            bookmarks: [
                BookmarkedQuestionResponseDTO(projectID: "project-1", setID: "set-1", questionID: "question-1")
            ],
        )))
        let adapter = BookmarkRepositoryAdapter(remote: remote)

        let collection = try await adapter.fetchBookmarkedQuestions(projectID: "project-1")

        #expect(collection.availableProjects == ["project-1", "project-2"])
        #expect(collection.totalCount == 2)
    }

    @Test
    func `목록 응답의 문제 본문을 그대로 보존한다`() async throws {
        let remote = StubBookmarkRemote(listResult: .success(BookmarkedQuestionListResponseDTO(
            totalCount: 1,
            availableProjects: [],
            bookmarks: [
                BookmarkedQuestionResponseDTO(
                    projectID: "project-1",
                    setID: "set-1",
                    questionID: "question-1",
                    question: "`androidApp`과 `desktopApp`이 공통으로 쓰는 코드는 어디에 있나요?",
                )
            ],
        )))
        let adapter = BookmarkRepositoryAdapter(remote: remote)

        let collection = try await adapter.fetchBookmarkedQuestions(projectID: nil)

        #expect(
            collection.bookmarks.map(\.prompt)
                == ["`androidApp`과 `desktopApp`이 공통으로 쓰는 코드는 어디에 있나요?"]
        )
    }

    @Test
    func `Data 오류를 Domain 오류로 변환한다`() async throws {
        let remote = StubBookmarkRemote(setResult: .failure(.unauthorized))
        let adapter = BookmarkRepositoryAdapter(remote: remote)

        await #expect(throws: LearningProjectError.unauthorized) {
            try await adapter.setBookmark(projectID: "project-1", questionID: "question-1", bookmarked: true)
        }
    }

}

// MARK: - StubBookmarkRemote

private struct StubBookmarkRemote: BookmarkRemote {
    var setResult = Result<BookmarkQuestionResponseDTO, DataLearningProjectError>.failure(.unexpectedStatus)
    var listResult = Result<BookmarkedQuestionListResponseDTO, DataLearningProjectError>.failure(.unexpectedStatus)

    func setBookmark(
        projectID _: String,
        questionID _: String,
        request _: BookmarkQuestionRequestDTO,
    ) async throws -> BookmarkQuestionResponseDTO {
        try setResult.get()
    }

    func fetchBookmarks(projectID _: String?) async throws -> BookmarkedQuestionListResponseDTO {
        try listResult.get()
    }
}
