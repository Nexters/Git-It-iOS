import Foundation
import Testing

@testable import InfrastructureNetworkClient

@Suite("HTTPClient 응답 전달")
struct ResponseDeliveryTests {

    // MARK: Internal

    @Test
    func `성공 응답은 변환한 본문과 상태 코드 및 헤더를 전달한다`() async throws {
        let expected = TestPayload(id: 7, name: "성공")
        let response: HTTPResponse<TestPayload> = try await send(
            statusCode: 201,
            headers: ["X-Request-ID": "request-1"],
            body: JSONEncoder().encode(expected),
        )

        #expect(response.statusCode == 201)
        #expect(response.headers["x-request-id"] == "request-1")
        guard case .decoded(let body) = response.body else {
            Issue.record("성공 상태 코드는 decoded 본문이어야 합니다.")
            return
        }
        #expect(body == expected)
    }

    @Test
    func `비성공 응답은 원형 본문을 실패 없이 전달한다`() async throws {
        let raw = Data("not-found".utf8)
        let response: HTTPResponse<TestPayload> = try await send(statusCode: 404, body: raw)

        guard case .raw(let body) = response.body else {
            Issue.record("비성공 상태 코드는 raw 본문이어야 합니다.")
            return
        }
        #expect(response.statusCode == 404)
        #expect(body == raw)
    }

    @Test
    func `비성공 응답 본문이 성공 형식과 달라도 변환 실패가 아니다`() async throws {
        let response: HTTPResponse<TestPayload> = try await send(statusCode: 500, body: Data("<html>error</html>".utf8))

        guard case .raw(let body) = response.body else {
            Issue.record("비성공 응답의 본문 변환을 시도하면 안 됩니다.")
            return
        }
        #expect(body == Data("<html>error</html>".utf8))
    }

    @Test
    func `빈 성공 본문은 본문 변환 규칙에 그대로 위임한다`() async throws {
        let transport = RecordingTransport([.response(.init(statusCode: 204, headers: [:], body: Data()))])
        let client = HTTPClient(
            baseURL: try #require(URL(string: "https://api.example.com")),
            bodyCoding: StubBodyCoding(allowsEmptyBody: true),
            transport: transport,
        )

        let response = try await client.send(
            HTTPRequest(method: .get, path: "empty"),
            expecting: EmptyPayload.self,
        )

        guard case .decoded(let body) = response.body else {
            Issue.record("빈 본문 허용 여부는 변환 규칙이 결정해야 합니다.")
            return
        }
        #expect(body == EmptyPayload())
    }

    @Test
    func `원소 없는 목록도 성공 응답 값으로 전달한다`() async throws {
        let response = try await send(statusCode: 200, body: Data("[]".utf8), expecting: [TestPayload].self)

        guard case .decoded(let body) = response.body else {
            Issue.record("빈 목록은 정상 변환 결과여야 합니다.")
            return
        }
        #expect(body.isEmpty)
    }

    @Test
    func `응답 헤더는 대소문자와 무관하게 조회한다`() async throws {
        let response = try await send(
            statusCode: 200,
            headers: ["X-Mixed-Case-Header": "value"],
            body: JSONEncoder().encode(TestPayload(id: 1, name: "응답")),
        )

        #expect(response.headers["x-mixed-case-header"] == "value")
        #expect(response.headers["X-MIXED-CASE-HEADER"] == "value")
    }

    // MARK: Private

    private func send(
        statusCode: Int,
        headers: HTTPHeaders = [:],
        body: Data,
    ) async throws -> HTTPResponse<TestPayload> {
        try await send(
            statusCode: statusCode,
            headers: headers,
            body: body,
            expecting: TestPayload.self,
        )
    }

    private func send<ResponseBody: Decodable & Sendable>(
        statusCode: Int,
        headers: HTTPHeaders = [:],
        body: Data,
        expecting: ResponseBody.Type,
    ) async throws -> HTTPResponse<ResponseBody> {
        let transport = RecordingTransport([.response(.init(statusCode: statusCode, headers: headers, body: body))])
        let client = HTTPClient(
            baseURL: URL(string: "https://api.example.com")!,
            bodyCoding: StubBodyCoding(),
            transport: transport,
        )
        return try await client.send(HTTPRequest(method: .get, path: "resource"), expecting: expecting)
    }

}
