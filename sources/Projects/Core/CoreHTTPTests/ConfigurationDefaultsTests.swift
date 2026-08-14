import Foundation
import Testing

@testable import CoreHTTP

@Suite("HTTPClient 구성 기본값")
struct ConfigurationDefaultsTests {

    // MARK: Internal

    @Test
    func `요청별 한도가 없으면 생성 시 대기 한도 15초를 사용한다`() async throws {
        // 생성자 인자를 생략한 호출 경로가 단일 기본값 정의(15초)를 실제 전송 요청까지 전달해야 합니다.
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
        // 요청 단위 설정은 같은 client의 공통 설정보다 항상 우선해야 합니다.
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
        // 호출자가 별도 구성 타입이나 상수를 알 필요 없이 이 공개 정적 값만 참조하면 됩니다.
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
