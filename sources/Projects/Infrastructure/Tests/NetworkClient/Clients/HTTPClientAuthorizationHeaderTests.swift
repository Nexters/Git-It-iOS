import Foundation
import Testing

@testable import InfrastructureNetworkClient

@Suite("HTTPClient 인증 헤더 병합 시점")
struct HTTPClientAuthorizationHeaderTests {

    // MARK: Internal

    @Test
    func `같은 클라이언트 인스턴스로 보낸 두 요청이 요청 시점의 최신 인증 헤더를 각각 반영한다`() async throws {
        let transport = RecordingTransport([.response(successResponse()), .response(successResponse())])
        let client = HTTPClient(
            baseURL: try #require(URL(string: "https://api.example.com/v1")),
            bodyCoding: StubBodyCoding(),
            commonHeaders: ["Accept": "application/json"],
            transport: transport,
        )

        _ = try await client.send(
            HTTPRequest(method: .get, path: "me", headers: ["Authorization": "Bearer first-token"]),
            expecting: TestPayload.self,
        )
        _ = try await client.send(
            HTTPRequest(method: .get, path: "me", headers: ["Authorization": "Bearer second-token"]),
            expecting: TestPayload.self,
        )

        let requests = await transport.requests
        #expect(requests.count == 2)
        #expect(requests[0].headers["Authorization"] == "Bearer first-token")
        #expect(requests[1].headers["Authorization"] == "Bearer second-token")
    }

    // MARK: Private

    private func successResponse() -> HTTPTransportResponse {
        HTTPTransportResponse(
            statusCode: 200,
            headers: [:],
            body: try! JSONEncoder().encode(TestPayload(id: 1, name: "응답")),
        )
    }

}
