import Foundation
import Testing

@testable import InfrastructureNetworkClient

@Suite("HTTPClient 동시성 격리")
struct ConcurrencyIsolationTests {

    // MARK: Internal

    @Test
    func `한 요청 취소가 동시에 전송한 다른 요청에 영향을 주지 않는다`() async throws {
        let response = HTTPTransportResponse(
            statusCode: 200,
            headers: [:],
            body: try JSONEncoder().encode(TestPayload(id: 1, name: "응답")),
        )
        let transport = RecordingTransport([.waitForCancellation] + Array(repeating: .response(response), count: 9))
        let client = client(transport: transport)
        let cancelled = Task { () throws(HTTPClientError) -> HTTPResponse<TestPayload> in
            try await client.send(HTTPRequest(method: .get, path: "cancelled"), expecting: TestPayload.self)
        }
        await transport.waitUntilCalled(1)

        let remaining = try await withThrowingTaskGroup(of: HTTPResponse<TestPayload>.self) { group in
            for index in 1 ... 9 {
                group.addTask {
                    try await client.send(
                        HTTPRequest(method: .get, path: "resource/\(index)"),
                        expecting: TestPayload.self,
                    )
                }
            }
            cancelled.cancel()
            var responses = [HTTPResponse<TestPayload>]()
            for try await response in group {
                responses.append(response)
            }
            return responses
        }

        await #expect(throws: HTTPClientError.cancelled) { try await cancelled.value }
        #expect(remaining.count == 9)
        let callCount = await transport.callCount
        #expect(callCount == 10)
    }

    @Test
    func `취소를 먼저 관찰한 요청은 반복해도 시간 초과보다 취소를 우선한다`() async {
        for _ in 0 ..< 20 {
            let transport = RecordingTransport([.waitForCancellation])
            let client = client(transport: transport, responseTimeout: .seconds(1))
            let task = Task { () throws(HTTPClientError) -> HTTPResponse<TestPayload> in
                try await client.send(HTTPRequest(method: .get, path: "resource"), expecting: TestPayload.self)
            }
            await transport.waitUntilCalled(1)
            task.cancel()

            await #expect(throws: HTTPClientError.cancelled) { try await task.value }
            let cancellationCount = await transport.cancellationCount
            #expect(cancellationCount == 1)
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

}
