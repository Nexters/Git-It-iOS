import Foundation
import InfrastructureNetworkClient
import Testing

@testable import DataLearningProject

@Suite("HTTPProjectRemote 인증 헤더")
struct HTTPProjectRemoteAuthorizationTests {

    // MARK: Internal

    @Test
    func `같은 Remote로 보낸 두 요청이 요청 시점의 최신 access token을 각각 반영한다`() async throws {
        var currentToken = "first-token"
        let transport = StubHTTPTransport(results: [
            .response(
                jsonResponse(#"{"success":true,"data":{"items":[],"hasNext":false},"code":null,"message":null,"errors":null}"#)
            ),
            .response(
                jsonResponse(#"{"success":true,"data":{"items":[],"hasNext":false},"code":null,"message":null,"errors":null}"#)
            ),
        ])
        let client = HTTPClient(
            baseURL: try #require(URL(string: "https://api.git-it.example.com")),
            bodyCoding: JSONBodyCoding(),
            transport: transport,
        )
        let remote = HTTPProjectRemote(client: client, accessTokenProvider: { currentToken })

        _ = try await remote.fetchProjects(page: 0, size: 10)
        currentToken = "second-token"
        _ = try await remote.fetchProjects(page: 0, size: 10)

        let requests = await transport.recordedRequests
        #expect(requests[0].headers["Authorization"] == "Bearer first-token")
        #expect(requests[1].headers["Authorization"] == "Bearer second-token")
    }

    // MARK: Private

    private func jsonResponse(_ envelope: String) -> HTTPTransportResponse {
        HTTPTransportResponse(statusCode: 200, headers: [:], body: Data(envelope.utf8))
    }

}
