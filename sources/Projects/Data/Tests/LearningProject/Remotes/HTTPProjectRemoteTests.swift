import Foundation
import InfrastructureNetworkClient
import Testing

@testable import DataLearningProject

// MARK: - HTTPProjectRemoteTests

@Suite("HTTPProjectRemote")
struct HTTPProjectRemoteTests {

    @Test
    func `프로젝트 목록 요청을 baseURL과 page 및 size query로 구성한다`() async throws {
        let transport = StubHTTPTransport(results: [
            .response(jsonResponse(
                statusCode: 200,
                envelope: #"{"success":true,"data":{"items":[],"hasNext":false},"code":null,"message":null,"errors":null}"#,
            ))
        ])
        let remote = makeRemote(transport: transport)

        let page = try await remote.fetchProjects(page: 2, size: 30)

        #expect(page.items.isEmpty)
        #expect(!page.hasNext)
        let request = await transport.recordedRequests.first
        #expect(request?.url.path == "/api/v1/projects")
        #expect(methodName(request?.method) == "GET")
        let queryItems = request.flatMap { URLComponents(url: $0.url, resolvingAgainstBaseURL: false)?.queryItems }
        #expect(queryItems?.contains(URLQueryItem(name: "page", value: "2")) == true)
        #expect(queryItems?.contains(URLQueryItem(name: "size", value: "30")) == true)
    }

    @Test
    func `프로젝트 상세 응답을 Domain 표기와 일치하는 DTO로 변환한다`() async throws {
        let transport = StubHTTPTransport(results: [
            .response(jsonResponse(
                statusCode: 200,
                envelope: #"""
                    {"success":true,"data":{"projectId":"project-1","repositoryUrl":"https://github.com/owner/repo","repositoryName":"repo","repositoryImageUrl":null,"starCount":3,"techStack":["Swift"],"overallProgressPercent":40,"nextQuestionId":"question-1","sets":[{"setId":"set-1","label":"Set 1","title":"title"}]},"code":null,"message":null,"errors":null}
                    """#,
            ))
        ])
        let remote = makeRemote(transport: transport)

        let detail = try await remote.fetchProjectDetail(projectID: "project-1")

        #expect(detail.projectID == "project-1")
        #expect(detail.repositoryURL == "https://github.com/owner/repo")
        #expect(detail.sets.first?.setID == "set-1")
        let request = await transport.recordedRequests.first
        #expect(request?.url.path == "/api/v1/projects/project-1")
    }

    @Test
    func `등록 요청 본문을 githubRepoUrl로 인코딩한다`() async throws {
        let transport = StubHTTPTransport(results: [
            .response(jsonResponse(
                statusCode: 200,
                envelope: #"{"success":true,"data":{"projectId":"project-1","requestStatus":"ready"},"code":null,"message":null,"errors":null}"#,
            ))
        ])
        let remote = makeRemote(transport: transport)

        let response = try await remote.registerProject(
            RegisterProjectRequestDTO(githubRepoURL: "https://github.com/owner/repo", quizLevel: .l1)
        )

        #expect(response.projectID == "project-1")
        let request = await transport.recordedRequests.first
        #expect(methodName(request?.method) == "POST")
        let body = try #require(request?.body)
        let decodedBody = try #require(JSONSerialization.jsonObject(with: body) as? [String: String])
        #expect(decodedBody["githubRepoUrl"] == "https://github.com/owner/repo")
    }

    @Test
    func `삭제 요청은 DELETE 메서드로 전송한다`() async throws {
        let transport = StubHTTPTransport(results: [
            .response(jsonResponse(
                statusCode: 200,
                envelope: #"{"success":true,"data":{},"code":null,"message":null,"errors":null}"#,
            ))
        ])
        let remote = makeRemote(transport: transport)

        try await remote.deleteProject(projectID: "project-1")

        let request = await transport.recordedRequests.first
        #expect(methodName(request?.method) == "DELETE")
        #expect(request?.url.path == "/api/v1/projects/project-1")
    }

    @Test
    func `서버 오류 코드를 Data 오류로 변환한다`() async throws {
        let transport = StubHTTPTransport(results: [
            .response(jsonResponse(
                statusCode: 404,
                envelope: #"{"success":false,"data":null,"code":"PROJECT-001","message":"not found","errors":null}"#,
            ))
        ])
        let remote = makeRemote(transport: transport)

        await #expect(throws: DataLearningProjectError.projectUnavailable) {
            try await remote.fetchProjectDetail(projectID: "missing")
        }
    }

    @Test
    func `연결 실패를 transport 오류로 변환한다`() async throws {
        let transport = StubHTTPTransport(results: [.failure(.connectionFailed)])
        let remote = makeRemote(transport: transport)

        await #expect(throws: DataLearningProjectError.transport) {
            try await remote.fetchProjects(page: 0, size: 10)
        }
    }

    @Test
    func `취소를 CancellationError로 그대로 전달한다`() async throws {
        let transport = StubHTTPTransport(results: [.failure(.cancelled)])
        let remote = makeRemote(transport: transport)

        await #expect(throws: CancellationError.self) {
            try await remote.fetchProjects(page: 0, size: 10)
        }
    }

}

extension HTTPProjectRemoteTests {
    private func makeRemote(transport: StubHTTPTransport) -> HTTPProjectRemote {
        let client = HTTPClient(
            baseURL: URL(string: "https://api.git-it.example.com")!,
            bodyCoding: JSONBodyCoding(),
            transport: transport,
        )
        return HTTPProjectRemote(client: client, accessTokenProvider: { "test-access-token" })
    }

    private func jsonResponse(
        statusCode: Int,
        envelope: String,
    ) -> HTTPTransportResponse {
        HTTPTransportResponse(statusCode: statusCode, headers: [:], body: Data(envelope.utf8))
    }

    private func methodName(_ method: InfrastructureNetworkClient.HTTPMethod?) -> String {
        switch method {
        case .get: "GET"
        case .post: "POST"
        case .put: "PUT"
        case .patch: "PATCH"
        case .delete: "DELETE"
        case .head: "HEAD"
        case nil: "NONE"
        @unknown default: "UNKNOWN"
        }
    }
}
