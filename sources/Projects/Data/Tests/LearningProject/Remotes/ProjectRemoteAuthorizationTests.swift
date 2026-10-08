import Foundation
import InfrastructureNetworkClient
import Synchronization
import Testing

@testable import DataLearningProject

@Suite("ProjectRemote 인증 헤더")
struct ProjectRemoteAuthorizationTests {

    // MARK: Internal

    @Test
    func `같은 Remote로 보낸 두 요청이 요청 시점의 최신 access token을 각각 반영한다`() async throws {
        let currentToken = Mutex("first-token")
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
        let remote = ProjectRemote(
            client: client,
            credential: { .available(currentToken.withLock { $0 }) },
            credentialRejected: { },
        )

        _ = try await remote.fetchProjects(
            page: 0,
            size: 10,
        )
        currentToken.withLock { $0 = "second-token" }
        _ = try await remote.fetchProjects(
            page: 0,
            size: 10,
        )

        let requests = await transport.recordedRequests
        #expect(requests[0].headers["Authorization"] == "Bearer first-token")
        #expect(requests[1].headers["Authorization"] == "Bearer second-token")
    }

    // MARK: Private

    private func jsonResponse(_ envelope: String) -> HTTPTransportResponse {
        HTTPTransportResponse(
            statusCode: 200,
            headers: [:],
            body: Data(envelope.utf8),
        )
    }

}
