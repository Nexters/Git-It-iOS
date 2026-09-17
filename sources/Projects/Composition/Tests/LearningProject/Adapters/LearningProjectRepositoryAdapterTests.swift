import Foundation
import Testing

@testable import CompositionLearningProject
@testable import DataLearningProject
@testable import DataShared
@testable import DomainLearningProject

// MARK: - LearningProjectRepositoryAdapterTests

@Suite("LearningProjectRepositoryAdapter")
struct LearningProjectRepositoryAdapterTests {

    // MARK: Internal

    @Test
    func `목록 응답 DTO를 Domain 모델로 변환하고 표기를 뒤집지 않는다`() async throws {
        let adapter = makeAdapter(transport: RecordingRequestTransport(results: [
            successResponse(#"""
                {"items":[{"projectId":"project-1","repositoryName":"repo","repositoryImageUrl":null,"techStack":["Swift"],"currentSetLabel":"Set 1","currentSetTitle":"title","nextSetId":"set-1","nextQuestionId":"question-1","overallProgressPercent":40}],"hasNext":true}
                """#)
        ]))

        let page = try await adapter.fetchProjects(page: 0, size: 10)

        #expect(page.items.first?.projectID == "project-1")
        #expect(page.items.first?.nextSetID == "set-1")
        #expect(page.hasNext)
    }

    @Test
    func `상세 응답 DTO를 Domain 모델로 변환한다`() async throws {
        let adapter = makeAdapter(transport: RecordingRequestTransport(results: [
            successResponse(#"""
                {"projectId":"project-1","repositoryUrl":"https://github.com/owner/repo","repositoryName":"repo","repositoryImageUrl":null,"starCount":3,"techStack":[],"overallProgressPercent":40,"nextQuestionId":"question-1","sets":[]}
                """#)
        ]))

        let detail = try await adapter.fetchProjectDetail(projectID: "project-1")

        #expect(detail.projectID == "project-1")
        #expect(detail.repositoryURL == "https://github.com/owner/repo")
    }

    @Test
    func `상세 응답의 세트 문제 수와 완료 수를 그대로 보존한다`() async throws {
        let adapter = makeAdapter(transport: RecordingRequestTransport(results: [
            successResponse(#"""
                {"projectId":"project-1","repositoryUrl":"https://github.com/owner/repo","repositoryName":"repo","repositoryImageUrl":null,"starCount":3,"techStack":[],"overallProgressPercent":40,"nextQuestionId":"question-1","sets":[{"setId":"set-1","label":"Set 1","title":"KMP 프로젝트 구조 확인하기","problemCount":5,"completedCount":2},{"setId":"set-2","label":"Set 2","title":"KDoc 주석 규칙 확인하기","problemCount":3,"completedCount":0}]}
                """#)
        ]))

        let detail = try await adapter.fetchProjectDetail(projectID: "project-1")

        #expect(detail.sets.map(\.setID) == ["set-1", "set-2"])
        #expect(detail.sets.map(\.problemCount) == [5, 3])
        #expect(detail.sets.map(\.completedCount) == [2, 0])
    }

    @Test
    func `등록 요청을 Data DTO로 위임하고 응답을 Domain 등록 결과로 변환한다`() async throws {
        let transport = RecordingRequestTransport(results: [
            successResponse(#"{"projectId":"project-1","status":"ready"}"#)
        ])
        let adapter = makeAdapter(transport: transport)

        let registration = try await adapter.register(githubRepoURL: "https://github.com/owner/repo", quizLevel: .l1)

        #expect(registration.projectID == "project-1")
        #expect(registration.requestStatus == "ready")
        #expect(registration.quizLevel == .l1)
        let request = try #require(await transport.recordedRequests.first)
        #expect(request.url.path == "/api/v1/projects")
        let rawBody = try #require(request.body)
        let body = try #require(JSONSerialization.jsonObject(with: rawBody) as? [String: String])
        #expect(body["githubRepoUrl"] == "https://github.com/owner/repo")
    }

    @Test
    func `Data 오류를 Domain 오류로 변환한다`() async throws {
        let adapter = makeAdapter(transport: RecordingRequestTransport(results: [
            errorResponse(statusCode: 404, code: "PROJECT-001")
        ]))

        await #expect(throws: LearningProjectError.notFound) {
            try await adapter.fetchProjectDetail(projectID: "missing")
        }
    }

    // MARK: Private

    private func makeAdapter(transport: RecordingRequestTransport) -> LearningProjectRepositoryAdapter {
        LearningProjectRepositoryAdapter(remote: ProjectRemote(
            baseURL: URL(string: "https://api.git-it.example.com")!,
            transport: transport,
            responseTimeout: RequestClientFactory.defaultResponseTimeout,
            credential: { .available("test-access-token") },
            credentialRejected: { },
        ))
    }

    private func successResponse(_ payload: String) -> TransportResponse {
        TransportResponse(
            statusCode: 200,
            body: Data(#"{"success":true,"data":\#(payload),"code":null,"message":null,"errors":null}"#.utf8),
        )
    }

    private func errorResponse(
        statusCode: Int,
        code: String,
    ) -> TransportResponse {
        TransportResponse(
            statusCode: statusCode,
            body: Data(#"{"success":false,"data":null,"code":"\#(code)","message":"error","errors":null}"#.utf8),
        )
    }

}
