import Foundation
import Testing

@testable import CompositionLearningProject
@testable import DataLearningProject
@testable import DomainLearningProject
@testable import InfrastructureNetworkClient

// MARK: - BookmarkRepositoryAdapterTests

@Suite("BookmarkRepositoryAdapter")
struct BookmarkRepositoryAdapterTests {

    // MARK: Internal

    @Test
    func `설정 응답 DTO를 서버가 돌려준 bool 정본으로 변환한다`() async throws {
        let adapter = makeAdapter(transport: RecordingHTTPTransport(results: [
            successResponse(#"{"bookmarked":true}"#)
        ]))

        let state = try await adapter.setBookmark(projectID: "project-1", questionID: "question-1", bookmarked: true)

        #expect(state.bookmarked)
    }

    @Test
    func `목록 응답의 availableProjects를 필터와 무관하게 그대로 보존한다`() async throws {
        let adapter = makeAdapter(transport: RecordingHTTPTransport(results: [
            successResponse(#"""
                {"totalCount":2,"availableProjects":[{"projectId":"project-1","projectName":"repo-1"},{"projectId":"project-2","projectName":"repo-2"}],"bookmarks":[{"projectId":"project-1","projectName":"repo-1","setId":"set-1","setLabel":"Set 1","problemNumber":1,"questionId":"question-1","question":"질문"}]}
                """#)
        ]))

        let collection = try await adapter.fetchBookmarkedQuestions(projectID: "project-1")

        #expect(collection.availableProjects == [
            BookmarkedProject(id: "project-1", name: "repo-1"),
            BookmarkedProject(id: "project-2", name: "repo-2"),
        ])
        #expect(collection.totalCount == 2)
    }

    @Test
    func `목록 응답의 문제 본문을 그대로 보존한다`() async throws {
        let adapter = makeAdapter(transport: RecordingHTTPTransport(results: [
            successResponse(#"""
                {"totalCount":1,"availableProjects":[],"bookmarks":[{"projectId":"project-1","projectName":"repo-1","setId":"set-1","setLabel":"Set 1","problemNumber":1,"questionId":"question-1","question":"`androidApp`과 `desktopApp`이 공통으로 쓰는 코드는 어디에 있나요?"}]}
                """#)
        ]))

        let collection = try await adapter.fetchBookmarkedQuestions(projectID: nil)

        #expect(
            collection.bookmarks.map(\.prompt)
                == ["`androidApp`과 `desktopApp`이 공통으로 쓰는 코드는 어디에 있나요?"]
        )
    }

    @Test
    func `목록 응답의 프로젝트명·세트 라벨·문제 번호를 그대로 보존한다`() async throws {
        let adapter = makeAdapter(transport: RecordingHTTPTransport(results: [
            successResponse(#"""
                {"totalCount":1,"availableProjects":[],"bookmarks":[{"projectId":"project-1","projectName":"Now in Android","setId":"set-1","setLabel":"Set 2","problemNumber":1,"questionId":"question-1","question":"질문"}]}
                """#)
        ]))

        let collection = try await adapter.fetchBookmarkedQuestions(projectID: nil)

        let bookmark = try #require(collection.bookmarks.first)
        #expect(bookmark.projectName == "Now in Android")
        #expect(bookmark.setLabel == "Set 2")
        #expect(bookmark.problemNumber == 1)
    }

    @Test
    func `Data 오류를 Domain 오류로 변환한다`() async throws {
        let adapter = makeAdapter(transport: RecordingHTTPTransport(results: [
            errorResponse(statusCode: 401, code: "AUTH-001")
        ]))

        await #expect(throws: LearningProjectError.unauthorized) {
            try await adapter.setBookmark(projectID: "project-1", questionID: "question-1", bookmarked: true)
        }
    }

    // MARK: Private

    private func makeAdapter(transport: RecordingHTTPTransport) -> BookmarkRepositoryAdapter {
        BookmarkRepositoryAdapter(remote: BookmarkRemote(
            client: HTTPClient(
                baseURL: URL(string: "https://api.git-it.example.com")!,
                bodyCoding: StandardJSONBodyCoding(),
                transport: transport,
            ),
            accessTokenProvider: { "test-access-token" },
        ))
    }

    private func successResponse(_ payload: String) -> HTTPTransportResponse {
        HTTPTransportResponse(
            statusCode: 200,
            headers: [:],
            body: Data(#"{"success":true,"data":\#(payload),"code":null,"message":null,"errors":null}"#.utf8),
        )
    }

    private func errorResponse(
        statusCode: Int,
        code: String,
    ) -> HTTPTransportResponse {
        HTTPTransportResponse(
            statusCode: statusCode,
            headers: [:],
            body: Data(#"{"success":false,"data":null,"code":"\#(code)","message":"error","errors":null}"#.utf8),
        )
    }

}
