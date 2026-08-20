import Foundation
import Testing

@testable import CompositionAdepter
@testable import DataLearningProject
@testable import InfrastructureNetworkClient

// MARK: - LearningProjectRemoteAdapterTests

@Suite("LearningProjectRemoteAdapter")
struct LearningProjectRemoteAdapterTests {
    @Test
    func `registerProject 성공 응답을 정확히 디코딩한다`() async throws {
        let json = """
            {"success":true,"data":{"projectId":"project-1","status":"READY"},"code":null,"message":null,"errors":null}
            """
        let adapter = makeAdapter(
            transport: FakeHTTPTransport(.response(makeResponse(200, json))),
            accessToken: nil,
        )

        let dto = try await adapter.registerProject(
            RegisterProjectRequestDTO(githubRepoUrl: "https://github.com/owner/repo", quizLevel: .l1)
        )

        #expect(dto.projectId == "project-1")
        #expect(dto.status == .ready)
    }

    @Test
    func `fetchProjects 성공 응답을 정확히 디코딩한다`() async throws {
        let json = """
            {"success":true,"data":{"items":[{"projectId":"project-1","repositoryName":"nexters","repositoryImageUrl":"https://avatars.githubusercontent.com/u/1","techStack":["Kotlin"],"currentSetLabel":"Set 1","currentSetTitle":"Set 1 title","nextSetId":"set1","nextQuestionId":"q3","overallProgressPercent":28}],"hasNext":false},"code":null,"message":null,"errors":null}
            """
        let adapter = makeAdapter(
            transport: FakeHTTPTransport(.response(makeResponse(200, json))),
            accessToken: nil,
        )

        let dto = try await adapter.fetchProjects(page: 0, size: 10)

        #expect(dto.hasNext == false)
        #expect(dto.items.first?.projectId == "project-1")
    }

    @Test
    func `fetchProjectDetail 성공 응답을 정확히 디코딩한다`() async throws {
        let json = """
            {"success":true,"data":{"projectId":"project-1","repositoryUrl":"https://github.com/nexters/nexters","repositoryName":"nexters","repositoryImageUrl":null,"starCount":3600,"techStack":["Kotlin"],"overallProgressPercent":28,"nextQuestionId":"q3","sets":[{"setId":"set1","label":"Set 1","title":"Set 1 title","problemCount":3,"completedCount":2}]},"code":null,"message":null,"errors":null}
            """
        let adapter = makeAdapter(
            transport: FakeHTTPTransport(.response(makeResponse(200, json))),
            accessToken: nil,
        )

        let dto = try await adapter.fetchProjectDetail(projectId: "project-1")

        #expect(dto.projectId == "project-1")
        #expect(dto.sets.first?.setId == "set1")
    }

    @Test
    func `deleteProject 성공 응답은 오류 없이 완료한다`() async throws {
        let json = """
            {"success":true,"data":null,"code":null,"message":null,"errors":null}
            """
        let adapter = makeAdapter(
            transport: FakeHTTPTransport(.response(makeResponse(200, json))),
            accessToken: nil,
        )

        try await adapter.deleteProject(projectId: "project-1")
    }

    @Test(arguments: [
        (400, DataLearningProjectError.invalidRequest),
        (401, .unauthorized),
        (404, .notFound),
        (500, .serverError),
    ])
    func `상태 코드가 대응 오류로 매핑된다`(statusCode: Int, expected: DataLearningProjectError) async throws {
        let json = """
            {"success":false,"data":null,"code":"ERR","message":"오류","errors":null}
            """
        let adapter = makeAdapter(
            transport: FakeHTTPTransport(.response(makeResponse(statusCode, json))),
            accessToken: nil,
        )

        await #expect(throws: expected) {
            try await adapter.fetchProjectDetail(projectId: "project-1")
        }
    }

    @Test
    func `HTTPClientError는 unexpected로 매핑된다`() async throws {
        let adapter = makeAdapter(
            transport: FakeHTTPTransport(.failure(.connectionFailed)),
            accessToken: nil,
        )

        await #expect(throws: DataLearningProjectError.unexpected) {
            try await adapter.fetchProjectDetail(projectId: "project-1")
        }
    }

    @Test
    func `세션이 있으면 Authorization Bearer 헤더를 첨부한다`() async throws {
        let transport = FakeHTTPTransport(.response(makeResponse(200, """
            {"success":true,"data":{"items":[],"hasNext":false},"code":null,"message":null,"errors":null}
            """)))
        let adapter = makeAdapter(transport: transport, accessToken: "access-token-123")

        _ = try await adapter.fetchProjects(page: 0, size: 10)

        let recordedHeaders = await transport.lastRequest?.headers
        #expect(recordedHeaders?["Authorization"] == "Bearer access-token-123")
    }

    @Test
    func `세션이 없으면 헤더 없이 요청해 서버의 401이 unauthorized로 도달한다`() async throws {
        let transport = FakeHTTPTransport(.response(makeResponse(401, """
            {"success":false,"data":null,"code":"COMMON-002","message":"인증이 필요합니다","errors":null}
            """)))
        let adapter = makeAdapter(transport: transport, accessToken: nil)

        await #expect(throws: DataLearningProjectError.unauthorized) {
            try await adapter.fetchProjects(page: 0, size: 10)
        }

        let recordedHeaders = await transport.lastRequest?.headers
        #expect(recordedHeaders?["Authorization"] == nil)
    }

    @Test
    func `registerProject는 POST api v1 projects로 요청 본문을 그대로 전송한다`() async throws {
        let transport = FakeHTTPTransport(.response(makeResponse(200, """
            {"success":true,"data":{"projectId":"project-1","status":"READY"},"code":null,"message":null,"errors":null}
            """)))
        let adapter = makeAdapter(transport: transport, accessToken: nil)
        let request = RegisterProjectRequestDTO(githubRepoUrl: "https://github.com/owner/repo", quizLevel: .l2)

        _ = try await adapter.registerProject(request)

        let recorded = await transport.lastRequest
        #expect(recorded?.method.requestValue == "POST")
        #expect(recorded?.url.path == "/api/v1/projects")
        let decodedBody = try JSONDecoder().decode(RegisterProjectRequestDTO.self, from: recorded?.body ?? Data())
        #expect(decodedBody == request)
    }

    @Test
    func `fetchProjects는 page와 size를 쿼리 파라미터로 전송한다`() async throws {
        let transport = FakeHTTPTransport(.response(makeResponse(200, """
            {"success":true,"data":{"items":[],"hasNext":false},"code":null,"message":null,"errors":null}
            """)))
        let adapter = makeAdapter(transport: transport, accessToken: nil)

        _ = try await adapter.fetchProjects(page: 2, size: 20)

        let recordedURL = await transport.lastRequest?.url
        #expect(recordedURL?.query()?.contains("page=2") == true)
        #expect(recordedURL?.query()?.contains("size=20") == true)
    }

    @Test
    func `fetchProjectDetail은 GET api v1 projects projectId로 전송한다`() async throws {
        let transport = FakeHTTPTransport(.response(makeResponse(200, """
            {"success":true,"data":{"projectId":"project-1","repositoryUrl":"u","repositoryName":"n","repositoryImageUrl":null,"starCount":0,"techStack":[],"overallProgressPercent":0,"nextQuestionId":null,"sets":[]},"code":null,"message":null,"errors":null}
            """)))
        let adapter = makeAdapter(transport: transport, accessToken: nil)

        _ = try await adapter.fetchProjectDetail(projectId: "project-1")

        let recorded = await transport.lastRequest
        #expect(recorded?.method.requestValue == "GET")
        #expect(recorded?.url.path == "/api/v1/projects/project-1")
    }

    @Test
    func `deleteProject는 DELETE api v1 projects projectId로 전송한다`() async throws {
        let transport = FakeHTTPTransport(.response(makeResponse(200, """
            {"success":true,"data":null,"code":null,"message":null,"errors":null}
            """)))
        let adapter = makeAdapter(transport: transport, accessToken: nil)

        try await adapter.deleteProject(projectId: "project-1")

        let recorded = await transport.lastRequest
        #expect(recorded?.method.requestValue == "DELETE")
        #expect(recorded?.url.path == "/api/v1/projects/project-1")
    }
}

extension LearningProjectRemoteAdapterTests {
    private func makeAdapter(
        transport: FakeHTTPTransport,
        accessToken: String?,
    ) -> LearningProjectRemoteAdapter {
        LearningProjectRemoteAdapter(
            httpClient: HTTPClient(
                baseURL: URL(string: "https://git-it.example.com")!,
                bodyCoding: JSONHTTPBodyCoding(),
                transport: transport,
            ),
            accessToken: { accessToken },
        )
    }

    private func makeResponse(
        _ statusCode: Int,
        _ json: String,
    ) -> HTTPTransportResponse {
        HTTPTransportResponse(statusCode: statusCode, headers: [:], body: Data(json.utf8))
    }
}
