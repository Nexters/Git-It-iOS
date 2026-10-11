import Foundation
import Testing

@testable import CompositionLearningProject
@testable import DataLearningProject
@testable import DataShared
@testable import DomainUseCaseInterface

// MARK: - QuizBookmarkRepositoryAdapterTests

@Suite("QuizBookmarkRepositoryAdapter")
struct QuizBookmarkRepositoryAdapterTests {

    // MARK: Internal

    @Test
    func `설정 응답 DTO를 서버가 돌려준 bool 정본으로 변환한다`() async throws {
        let adapter = Self.makeAdapter(transport: RecordingRequestTransport(results: [
            Self.successResponse(#"{"bookmarked":true}"#)
        ]))

        let state = try await adapter.setBookmark(
            "question-1",
            in: "project-1",
            isBookmarked: true,
        )

        #expect(state == QuizBookmarkState(
            quizID: "question-1",
            isBookmarked: true,
        ))
    }

    @Test
    func `목록 응답의 availableProjects를 필터와 무관하게 그대로 보존한다`() async throws {
        let adapter = Self.makeAdapter(transport: RecordingRequestTransport(results: [
            Self.successResponse(#"""
                {"totalCount":2,"availableProjects":[{"projectId":"project-1","projectName":"repo-1"},{"projectId":"project-2","projectName":"repo-2"}],"bookmarks":[{"projectId":"project-1","projectName":"repo-1","setId":"set-1","setLabel":"Set 1","problemNumber":1,"questionId":"question-1","question":"질문"}]}
                """#)
        ]))

        let list = try await adapter.bookmarks(.project("project-1"))

        #expect(list.projects == [
            QuizBookmarkProject(
                id: "project-1",
                name: "repo-1",
            ),
            QuizBookmarkProject(
                id: "project-2",
                name: "repo-2",
            ),
        ])
        #expect(list.totalCount == 2)
    }

    @Test
    func `목록 응답의 문제 본문을 그대로 보존한다`() async throws {
        let adapter = Self.makeAdapter(transport: RecordingRequestTransport(results: [
            Self.successResponse(#"""
                {"totalCount":1,"availableProjects":[],"bookmarks":[{"projectId":"project-1","projectName":"repo-1","setId":"set-1","setLabel":"Set 1","problemNumber":1,"questionId":"question-1","question":"`androidApp`과 `desktopApp`이 공통으로 쓰는 코드는 어디에 있나요?"}]}
                """#)
        ]))

        let list = try await adapter.bookmarks(.all)

        #expect(
            list.bookmarks.map(\.prompt)
                == ["`androidApp`과 `desktopApp`이 공통으로 쓰는 코드는 어디에 있나요?"]
        )
    }

    @Test
    func `목록 응답의 프로젝트명·세트 라벨·문제 번호를 그대로 보존한다`() async throws {
        let adapter = Self.makeAdapter(transport: RecordingRequestTransport(results: [
            Self.successResponse(#"""
                {"totalCount":1,"availableProjects":[],"bookmarks":[{"projectId":"project-1","projectName":"Now in Android","setId":"set-1","setLabel":"Set 2","problemNumber":1,"questionId":"question-1","question":"질문"}]}
                """#)
        ]))

        let list = try await adapter.bookmarks(.all)

        let bookmark = try #require(list.bookmarks.first)
        #expect(bookmark == QuizBookmark(
            projectID: "project-1",
            projectName: "Now in Android",
            setID: "set-1",
            setLabel: "Set 2",
            problemNumber: 1,
            quizID: "question-1",
            prompt: "질문",
        ))
    }

    @Test
    func `Data 오류를 Domain 오류로 변환한다`() async {
        let adapter = Self.makeAdapter(transport: RecordingRequestTransport(results: [
            Self.errorResponse(
                statusCode: 401,
                code: "AUTH-001",
            )
        ]))

        await #expect(throws: QuizDetailError.unauthorized) {
            _ = try await adapter.setBookmark(
                "question-1",
                in: "project-1",
                isBookmarked: true,
            )
        }
    }

    // MARK: Private

    private static func makeAdapter(transport: RecordingRequestTransport) -> QuizBookmarkRepositoryAdapter {
        QuizBookmarkRepositoryAdapter(remote: BookmarkRemote(
            baseURL: URL(string: "https://api.git-it.example.com")!,
            transport: transport,
            responseTimeout: RequestClientFactory.defaultResponseTimeout,
            credential: { .available("test-access-token") },
            credentialRejected: { },
        ))
    }

    private static func successResponse(_ payload: String) -> TransportResponse {
        TransportResponse(
            statusCode: 200,
            body: Data(#"{"success":true,"data":\#(payload),"code":null,"message":null,"errors":null}"#.utf8),
        )
    }

    private static func errorResponse(
        statusCode: Int,
        code: String,
    ) -> TransportResponse {
        TransportResponse(
            statusCode: statusCode,
            body: Data(#"{"success":false,"data":null,"code":"\#(code)","message":"error","errors":null}"#.utf8),
        )
    }

}
