import Foundation
import Testing

@testable import DataShared
@testable import InfrastructureNetworkClient

// MARK: - RequestTransportBridgeTests

@Suite("RequestTransportBridge")
struct RequestTransportBridgeTests {

    // MARK: Internal

    @Test
    func `요청의 URL과 헤더와 본문을 주입한 전송에 전달한다`() async throws {
        let transport = StubRequestTransport(result: .success(TransportResponse(statusCode: 200, body: Data("{}".utf8))))
        let client = Self.makeClient(transport: transport)

        _ = try await client.send(
            HTTPRequest(method: .post, path: "/api/v1/items", headers: ["Authorization": "Bearer token"]),
            body: ["name": "value"],
            expecting: EmptyBody.self,
        )

        let request = try #require(await transport.recordedRequests.first)
        #expect(request.url.absoluteString == "https://api.example.com/api/v1/items")
        #expect(request.headerFields["authorization"] == "Bearer token")
        let body = try #require(request.body)
        #expect(try JSONDecoder().decode([String: String].self, from: body) == ["name": "value"])
    }

    @Test
    func `응답의 상태 코드와 본문을 그대로 돌려준다`() async throws {
        let transport = StubRequestTransport(result: .success(TransportResponse(
            statusCode: 200,
            body: Data(#"{"name":"value"}"#.utf8),
        )))
        let client = Self.makeClient(transport: transport)

        let response = try await client.send(HTTPRequest(method: .get, path: "/items"), expecting: [String: String].self)

        #expect(response.statusCode == 200)
        guard case .decoded(let decoded) = response.body else {
            Issue.record("응답 본문을 해석하지 못했습니다")
            return
        }
        #expect(decoded == ["name": "value"])
    }

    @Test(arguments: [
        (RequestTransportError.cancelled, HTTPClientError.cancelled),
        (RequestTransportError.timedOut, HTTPClientError.timedOut),
        (RequestTransportError.connectionFailed, HTTPClientError.connectionFailed),
    ])
    func `전송 오류를 같은 의미의 요청 오류로 바꾼다`(
        transportError: RequestTransportError,
        clientError: HTTPClientError,
    ) async throws {
        let bridge = RequestTransportBridge(transport: StubRequestTransport(result: .failure(transportError)))

        await #expect(throws: clientError) {
            _ = try await bridge.send(HTTPTransportRequest(
                url: try #require(URL(string: "https://api.example.com/items")),
                method: .get,
                headers: [:],
                body: nil,
                responseTimeout: .seconds(1),
            ))
        }
    }

    // MARK: Private

    private struct EmptyBody: Decodable, Sendable { }

    private static func makeClient(transport: StubRequestTransport) -> HTTPClient {
        RequestClientFactory.makeClient(
            baseURL: URL(string: "https://api.example.com")!,
            transport: transport,
            responseTimeout: .seconds(1),
        )
    }

}
