import Foundation
import Testing

@testable import CoreHTTP

@Suite("HTTPClient 동시성 격리")
struct ConcurrencyIsolationTests {

    // MARK: Internal

    @Test
    func `한 요청 취소가 동시에 전송한 다른 요청에 영향을 주지 않는다`() async throws {
        // 첫 번째 대역 동작만 취소될 때까지 대기시키고, 나머지 아홉 개는 즉시 성공시킵니다.
        // 따라서 취소가 client 전체 상태를 오염하면 다른 요청도 실패하는 형태로 검출됩니다.
        let response = HTTPTransportResponse(
            statusCode: 200,
            headers: [:],
            body: try JSONEncoder().encode(TestPayload(id: 1, name: "응답")),
        )
        let transport = RecordingTransport([.waitForCancellation] + Array(repeating: .response(response), count: 9))
        let client = client(transport: transport)
        // 취소 대상이 실제로 transport에 도달한 뒤에만 취소해 실행 순서 경쟁을 제거합니다.
        let cancelled = Task { () throws(HTTPClientError) -> HTTPResponse<TestPayload> in
            try await client.send(HTTPRequest(method: .get, path: "cancelled"), expecting: TestPayload.self)
        }
        await transport.waitUntilCalled(1)

        // 독립된 아홉 작업을 같은 client로 동시에 보낸 뒤 첫 작업만 취소합니다.
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
        // 시간 초과 시점과 취소 시점을 맞추는 벽시계 경쟁은 비결정적입니다.
        // 대신 transport가 취소를 관찰할 수 있는 상태가 된 후, 충분히 큰 1초 한도 안에서 취소합니다.
        for _ in 0 ..< 20 {
            let transport = RecordingTransport([.waitForCancellation])
            let client = client(transport: transport, responseTimeout: .seconds(1))
            let task = Task { () throws(HTTPClientError) -> HTTPResponse<TestPayload> in
                try await client.send(HTTPRequest(method: .get, path: "resource"), expecting: TestPayload.self)
            }
            // 여기까지 오면 전송 작업은 이미 대기 중이므로 cancelled가 우선하는 경로를 결정적으로 재현합니다.
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
