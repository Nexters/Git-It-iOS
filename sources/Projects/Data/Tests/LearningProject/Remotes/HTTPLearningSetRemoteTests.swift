import Foundation
import InfrastructureNetworkClient
import Testing

@testable import DataLearningProject

// MARK: - HTTPLearningSetRemoteTests

@Suite("HTTPLearningSetRemote")
struct HTTPLearningSetRemoteTests {

    @Test
    func `학습 세트 상세 요청을 projectID와 setID 경로로 구성한다`() async throws {
        let transport = StubHTTPTransport(results: [
            .response(jsonResponse(
                statusCode: 200,
                envelope: #"""
                    {"success":true,"data":{"setId":"set-1","title":"제목","description":"설명","orientation":"front","level":"L1","questions":[]},"code":null,"message":null,"errors":null}
                    """#,
            ))
        ])
        let remote = makeRemote(transport: transport)

        let set = try await remote.fetchLearningSet(projectID: "project-1", setID: "set-1")

        #expect(set.setID == "set-1")
        let request = try #require(await transport.recordedRequests.first)
        #expect(request.url.path == "/api/v1/projects/project-1/sets/set-1")
        #expect(request.headers["Authorization"] == "Bearer test-access-token")
    }

    @Test
    func `서버 오류 코드를 Data 오류로 변환한다`() async throws {
        let transport = StubHTTPTransport(results: [
            .response(jsonResponse(
                statusCode: 404,
                envelope: #"{"success":false,"data":null,"code":"QUIZ-006","message":"not found","errors":null}"#,
            ))
        ])
        let remote = makeRemote(transport: transport)

        await #expect(throws: DataLearningProjectError.learningSetUnavailable) {
            try await remote.fetchLearningSet(projectID: "project-1", setID: "missing")
        }
    }

}

extension HTTPLearningSetRemoteTests {
    private func makeRemote(transport: StubHTTPTransport) -> HTTPLearningSetRemote {
        let client = HTTPClient(
            baseURL: URL(string: "https://api.git-it.example.com")!,
            bodyCoding: JSONBodyCoding(),
            transport: transport,
        )
        return HTTPLearningSetRemote(client: client, accessTokenProvider: { "test-access-token" })
    }

    private func jsonResponse(
        statusCode: Int,
        envelope: String,
    ) -> HTTPTransportResponse {
        HTTPTransportResponse(statusCode: statusCode, headers: [:], body: Data(envelope.utf8))
    }
}
