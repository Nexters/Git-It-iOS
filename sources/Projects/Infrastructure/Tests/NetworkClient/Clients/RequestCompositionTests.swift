import Foundation
import Testing

@testable import InfrastructureNetworkClient

@Suite("HTTPClient 요청 구성")
struct RequestCompositionTests {

    // MARK: Internal

    @Test
    func `기본 주소와 공통 헤더를 상대 경로 요청에 결합한다`() async throws {
        let transport = RecordingTransport([.response(successResponse())])
        let client = client(transport: transport, commonHeaders: ["Accept": "application/json"])

        _ = try await client.send(
            HTTPRequest(method: .get, path: "users"),
            expecting: TestPayload.self,
        )

        let requests = await transport.requests
        let request = try #require(requests.first)
        #expect(request.url.absoluteString == "https://api.example.com/v1/users")
        #expect(request.headers["accept"] == "application/json")
    }

    @Test
    func `기본 주소 끝 슬래시 유무가 경로 결합 결과를 바꾸지 않는다`() async throws {
        let withoutSlashTransport = RecordingTransport([.response(successResponse())])
        let withSlashTransport = RecordingTransport([.response(successResponse())])
        let request = HTTPRequest(method: .get, path: "users")

        _ = try await client(baseURL: try #require(URL(string: "https://api.example.com/v1")), transport: withoutSlashTransport)
            .send(request, expecting: TestPayload.self)
        _ = try await client(baseURL: try #require(URL(string: "https://api.example.com/v1/")), transport: withSlashTransport)
            .send(request, expecting: TestPayload.self)

        let withoutSlashRequests = await withoutSlashTransport.requests
        let withSlashRequests = await withSlashTransport.requests
        #expect(withoutSlashRequests.first?.url == withSlashRequests.first?.url)
    }

    @Test
    func `요청별 헤더가 표기와 무관하게 공통 헤더를 하나로 덮어쓴다`() async throws {
        let transport = RecordingTransport([.response(successResponse())])
        let client = client(transport: transport, commonHeaders: ["Content-Type": "application/json"])

        _ = try await client.send(
            HTTPRequest(method: .get, path: "users", headers: ["content-type": "text/plain"]),
            expecting: TestPayload.self,
        )

        let requests = await transport.requests
        let headers = try #require(requests.first).headers
        #expect(headers["CONTENT-TYPE"] == "text/plain")
        #expect(headers.names == ["content-type"])
    }

    @Test
    func `쿼리 예약 문자와 비ASCII 값을 의미 손실 없이 부호화한다`() async throws {
        let transport = RecordingTransport([.response(successResponse())])
        let request = HTTPRequest(
            method: .get,
            path: "search",
            queryItems: [.init(name: "q", value: "a b 한글+&=")],
        )

        _ = try await client(transport: transport).send(request, expecting: TestPayload.self)

        let requests = await transport.requests
        let requestURL = try #require(requests.first).url
        #expect(requestURL.absoluteString == "https://api.example.com/v1/search?q=a%20b%20%ED%95%9C%EA%B8%80%2B%26%3D")
    }

    @Test
    func `같은 이름 쿼리의 순서와 빈 값을 보존한다`() async throws {
        let transport = RecordingTransport([.response(successResponse())])
        let request = HTTPRequest(
            method: .get,
            path: "search",
            queryItems: [
                .init(name: "tag", value: "swift"),
                .init(name: "tag", value: "ios"),
                .init(name: "empty", value: ""),
            ],
        )

        _ = try await client(transport: transport).send(request, expecting: TestPayload.self)

        let requests = await transport.requests
        #expect(try #require(requests.first).url.query == "tag=swift&tag=ios&empty=")
    }

    @Test
    func `본문 변환 결과를 전송 수단에 그대로 전달한다`() async throws {
        let transport = RecordingTransport([.response(successResponse())])
        let body = TestPayload(id: 1, name: "새 요청")
        let expectedBody = Data("encoded request".utf8)

        _ = try await client(
            transport: transport,
            bodyCoding: StubBodyCoding(encodedBody: expectedBody),
        ).send(
            HTTPRequest(method: .post, path: "users"),
            body: body,
            expecting: TestPayload.self,
        )

        let requests = await transport.requests
        let sent = try #require(requests.first)
        #expect(sent.body == expectedBody)
    }

    // MARK: Private

    private func client(
        baseURL: URL = URL(string: "https://api.example.com/v1")!,
        transport: RecordingTransport,
        bodyCoding: any HTTPBodyCoding = StubBodyCoding(),
        commonHeaders: HTTPHeaders = [:],
    ) -> HTTPClient {
        HTTPClient(
            baseURL: baseURL,
            bodyCoding: bodyCoding,
            commonHeaders: commonHeaders,
            transport: transport,
        )
    }

    private func successResponse() -> HTTPTransportResponse {
        HTTPTransportResponse(
            statusCode: 200,
            headers: [:],
            body: try! JSONEncoder().encode(TestPayload(id: 1, name: "응답")),
        )
    }

}
