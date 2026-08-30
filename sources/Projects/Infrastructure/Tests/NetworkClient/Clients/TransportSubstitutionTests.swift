import Foundation
import Testing

@testable import InfrastructureNetworkClient

@Suite("HTTPTransport 대체")
struct TransportSubstitutionTests {

    // MARK: Internal

    @Test
    func `미리 정한 응답을 실제 네트워크 없이 전달한다`() async throws {
        let expected = TestPayload(id: 3, name: "대역 응답")
        let transport = RecordingTransport([.response(.init(
            statusCode: 200,
            headers: [:],
            body: try JSONEncoder().encode(expected),
        ))])

        let response = try await client(transport: transport).send(
            HTTPRequest(method: .get, path: "resource"),
            expecting: TestPayload.self,
        )

        guard case .decoded(let body) = response.body else {
            Issue.record("대체 전송 수단의 성공 응답은 변환돼야 합니다.")
            return
        }
        #expect(body == expected)
    }

    @Test
    func `대체 전송 수단의 실패를 그대로 전달한다`() async {
        let transport = RecordingTransport([.failure(.connectionFailed)])

        await #expect(throws: HTTPClientError.connectionFailed) {
            try await client(transport: transport).send(
                HTTPRequest(method: .get, path: "resource"),
                expecting: TestPayload.self,
            )
        }
    }

    @Test
    func `기록된 전송 요청에서 조립 결과를 검사한다`() async throws {
        let responseBody = TestPayload(id: 1, name: "응답")
        let expectedBody = Data("encoded request".utf8)
        let transport = RecordingTransport([.response(.init(
            statusCode: 200,
            headers: [:],
            body: try JSONEncoder().encode(responseBody),
        ))])
        let body = TestPayload(id: 11, name: "본문")
        let request = HTTPRequest(
            method: .patch,
            path: "items/11",
            queryItems: [.init(name: "q", value: "a+b")],
            headers: ["X-Request": "request"],
            responseTimeout: .seconds(3),
        )

        _ = try await client(
            transport: transport,
            bodyCoding: StubBodyCoding(encodedBody: expectedBody),
            commonHeaders: ["Accept": "application/json"],
        ).send(
            request,
            body: body,
            expecting: TestPayload.self,
        )

        let requests = await transport.requests
        let sent = try #require(requests.first)
        if case .patch = sent.method {
        } else {
            Issue.record("전송 요청의 방식이 patch가 아닙니다.")
        }
        #expect(sent.url.absoluteString == "https://api.example.com/v1/items/11?q=a%2Bb")
        #expect(sent.headers["accept"] == "application/json")
        #expect(sent.headers["x-request"] == "request")
        #expect(sent.body == expectedBody)
        #expect(sent.responseTimeout == .seconds(3))
    }

    @Test
    func `비성공 상태와 원형 본문도 대체 전송 수단으로 검사한다`() async throws {
        let raw = Data("service unavailable".utf8)
        let transport = RecordingTransport([.response(.init(statusCode: 503, headers: ["Retry-After": "30"], body: raw))])

        let response = try await client(transport: transport).send(
            HTTPRequest(method: .get, path: "resource"),
            expecting: TestPayload.self,
        )

        #expect(response.statusCode == 503)
        #expect(response.headers["retry-after"] == "30")
        guard case .raw(let body) = response.body else {
            Issue.record("비성공 응답은 raw 본문이어야 합니다.")
            return
        }
        #expect(body == raw)
    }

    // MARK: Private

    private func client(
        transport: RecordingTransport,
        bodyCoding: any HTTPBodyCoding = StubBodyCoding(),
        commonHeaders: HTTPHeaders = [:],
    ) -> HTTPClient {
        HTTPClient(
            baseURL: URL(string: "https://api.example.com/v1")!,
            bodyCoding: bodyCoding,
            commonHeaders: commonHeaders,
            transport: transport,
        )
    }

}
