import Foundation
import Testing

@testable import InfrastructureNetworkClient

@Suite("HTTPClient 구성 기본값")
struct ConfigurationDefaultsTests {

    // MARK: Internal

    @Test
    func `요청별 한도가 없으면 생성 시 대기 한도 15초를 사용한다`() async throws {
        let transport = RecordingTransport([.response(successResponse())])
        let client = HTTPClient(
            baseURL: try #require(URL(string: "https://api.example.com")),
            bodyCoding: StubBodyCoding(),
            transport: transport,
        )

        _ = try await client.send(HTTPRequest(method: .get, path: "resource"), expecting: TestPayload.self)

        let requests = await transport.requests
        let request = try #require(requests.first)
        #expect(request.responseTimeout == .seconds(15))
    }

    @Test
    func `요청별 대기 한도가 생성 시 값을 대신한다`() async throws {
        let transport = RecordingTransport([.response(successResponse())])
        let client = HTTPClient(
            baseURL: try #require(URL(string: "https://api.example.com")),
            bodyCoding: StubBodyCoding(),
            responseTimeout: .seconds(9),
            transport: transport,
        )

        _ = try await client.send(
            HTTPRequest(method: .get, path: "resource", responseTimeout: .seconds(2)),
            expecting: TestPayload.self,
        )

        let requests = await transport.requests
        #expect(try #require(requests.first).responseTimeout == .seconds(2))
    }

    @Test
    func `기본 대기 한도는 HTTPClient의 정적 정의 하나로 제공한다`() {
        #expect(HTTPClient.defaultResponseTimeout == .seconds(15))
    }

    // MARK: Private

    private func successResponse() -> HTTPTransportResponse {
        .init(
            statusCode: 200,
            headers: [:],
            body: try! JSONEncoder().encode(TestPayload(id: 1, name: "응답")),
        )
    }

}
