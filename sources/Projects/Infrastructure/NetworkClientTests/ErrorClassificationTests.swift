import Foundation
import Testing

@testable import InfrastructureNetworkClient

@Suite("HTTPClient 실패 분류")
struct ErrorClassificationTests {

    // MARK: Internal

    @Test(arguments: [HTTPClientError.connectionFailed, .timedOut, .cancelled])
    func `전송 수단 실패를 동일한 원인으로 전달한다`(expectedError: HTTPClientError) async {
        // Transport가 허용된 세 전송 오류를 던지면 HTTPClient는 다른 오류로 뭉개지 않습니다.
        let transport = RecordingTransport([.failure(expectedError)])
        let client = client(transport: transport)

        await #expect(throws: expectedError) {
            try await client.send(HTTPRequest(method: .get, path: "resource"), expecting: TestPayload.self)
        }
    }

    @Test
    func `응답하지 않는 전송 수단은 대기 한도 초과로 끝난다`() async {
        // suspended는 응답을 만들지 않으므로 클라이언트가 소유한 마감 작업만 테스트를 끝낼 수 있습니다.
        let transport = RecordingTransport([.suspended])
        let client = client(transport: transport, responseTimeout: .milliseconds(20))

        await #expect(throws: HTTPClientError.timedOut) {
            try await client.send(HTTPRequest(method: .get, path: "resource"), expecting: TestPayload.self)
        }
        let callCount = await transport.callCount
        #expect(callCount == 1)
    }

    @Test
    func `요청 본문 변환 실패는 전송 전에 중단한다`() async throws {
        // 인코딩은 HTTPTransport.send보다 앞 단계이므로 호출 횟수 0이 중요한 검증입니다.
        let transport = RecordingTransport([.response(successResponse())])
        let client = HTTPClient(
            baseURL: try #require(URL(string: "https://api.example.com")),
            bodyCoding: StubBodyCoding(failsEncoding: true),
            transport: transport,
        )

        await #expect(throws: HTTPClientError.requestEncodingFailed) {
            try await client.send(
                HTTPRequest(method: .post, path: "resource"),
                body: TestPayload(id: 1, name: "본문"),
                expecting: TestPayload.self,
            )
        }
        let callCount = await transport.callCount
        #expect(callCount == 0)
    }

    @Test
    func `절대 요청 대상을 만들 수 없으면 전송 전에 중단한다`() async throws {
        // 상대 baseURL은 scheme과 host가 없어 absolute transport request를 구성할 수 없습니다.
        let transport = RecordingTransport([.response(successResponse())])
        let client = HTTPClient(
            baseURL: try #require(URL(string: "relative-base")),
            bodyCoding: StubBodyCoding(),
            transport: transport,
        )

        await #expect(throws: HTTPClientError.invalidURL) {
            try await client.send(HTTPRequest(method: .get, path: "resource"), expecting: TestPayload.self)
        }
        let callCount = await transport.callCount
        #expect(callCount == 0)
    }

    @Test
    func `성공 본문 변환 실패를 별도 원인으로 전달한다`() async throws {
        // 응답은 수신했으므로 connectionFailed가 아니라 responseDecodingFailed여야 합니다.
        let transport = RecordingTransport([.response(successResponse())])
        let client = HTTPClient(
            baseURL: try #require(URL(string: "https://api.example.com")),
            bodyCoding: StubBodyCoding(failsDecoding: true),
            transport: transport,
        )

        await #expect(throws: HTTPClientError.responseDecodingFailed) {
            try await client.send(HTTPRequest(method: .get, path: "resource"), expecting: TestPayload.self)
        }
    }

    @Test
    func `연결 실패와 시간 초과 뒤 자동 재시도하지 않는다`() async {
        // 대역의 동작을 하나만 넣어 두고 호출 횟수를 확인해 숨은 retry를 검출합니다.
        for error in [HTTPClientError.connectionFailed, .timedOut] {
            let transport = RecordingTransport([.failure(error)])

            await #expect(throws: error) {
                try await client(transport: transport).send(
                    HTTPRequest(method: .get, path: "resource"),
                    expecting: TestPayload.self,
                )
            }
            let callCount = await transport.callCount
            #expect(callCount == 1)
        }
    }

    @Test
    func `여섯 실패 원인은 default 없는 switch로 모두 분기할 수 있다`() {
        // 새 오류 케이스가 추가되면 이 switch가 컴파일되지 않아 호출자 분기 계약이 드러납니다.
        let errors: [HTTPClientError] = [
            .invalidURL,
            .requestEncodingFailed,
            .connectionFailed,
            .timedOut,
            .cancelled,
            .responseDecodingFailed,
        ]

        for error in errors {
            let label =
                switch error {
                case .invalidURL: "invalidURL"
                case .requestEncodingFailed: "requestEncodingFailed"
                case .connectionFailed: "connectionFailed"
                case .timedOut: "timedOut"
                case .cancelled: "cancelled"
                case .responseDecodingFailed: "responseDecodingFailed"
                }
            #expect(!label.isEmpty)
        }
    }

    // MARK: Private

    private func client(
        transport: RecordingTransport,
        responseTimeout: Duration = .seconds(1),
    ) -> HTTPClient {
        HTTPClient(
            baseURL: URL(string: "https://api.example.com")!,
            bodyCoding: StubBodyCoding(),
            responseTimeout: responseTimeout,
            transport: transport,
        )
    }

    private func successResponse() -> HTTPTransportResponse {
        .init(statusCode: 200, headers: [:], body: Data("{}".utf8))
    }

}
