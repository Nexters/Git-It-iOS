import Testing

@testable import DataLearningProject

@Suite("BookmarkRemote 계약")
struct LearningProjectBookmarkContractTests {

    @Test
    func `북마크 설정은 toggle이 아니라 최종 상태를 전달한다`() async throws {
        let remote = LearningProjectRemoteProbe()

        let response = try await remote.setBookmark(
            projectID: "project-1",
            questionID: "question-1",
            request: BookmarkQuestionRequestDTO(bookmarked: true),
        )

        #expect(response.bookmarked)
        #expect(await remote.recordedCalls() == [.setBookmark])
    }

    @Test
    func `북마크 목록 item은 projectId와 setID, questionId를 모두 보존한다`() {
        let item = BookmarkedQuestionResponseDTO(projectID: "project-1", setID: "set-1", questionID: "question-1")

        #expect(item.projectID == "project-1")
        #expect(item.setID == "set-1")
        #expect(item.questionID == "question-1")
    }

    @Test
    func `북마크 목록을 조회한다`() async throws {
        let remote = LearningProjectRemoteProbe()

        let response = try await remote.fetchBookmarks(projectID: nil)

        #expect(response.totalCount == 0)
        #expect(await remote.recordedCalls() == [.fetchBookmarks])
    }

}
