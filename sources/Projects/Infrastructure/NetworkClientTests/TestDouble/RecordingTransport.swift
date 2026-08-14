import Foundation

@testable import InfrastructureNetworkClient

/// 실제 URL Loading System을 사용하지 않고 `HTTPClient`의 경계 동작을 검증하는 전송 대역입니다.
///
/// actor로 만들어 동시 요청 테스트에서도 요청 기록의 순서와 호출 횟수를 안전하게 관찰합니다.
actor RecordingTransport: HTTPTransport {

    // MARK: Lifecycle

    init(_ behaviors: [Behavior]) {
        self.behaviors = behaviors
    }

    // MARK: Internal

    enum Behavior: Sendable {
        /// 즉시 반환할 성공 또는 비성공 HTTP 응답입니다.
        case response(HTTPTransportResponse)
        /// 전송 계층에서 발생한 것으로 간주할 프로젝트 소유 오류입니다.
        case failure(HTTPClientError)
        /// 응답을 만들지 않고 취소될 때까지 대기해 클라이언트의 마감 시한을 검증합니다.
        case suspended
        /// 취소 관측 사실 자체를 검증할 수 있도록 취소될 때까지 대기합니다.
        case waitForCancellation
    }

    var requests: [HTTPTransportRequest] {
        recordedRequests
    }

    var callCount: Int {
        recordedRequests.count
    }

    var cancellationCount: Int {
        observedCancellationCount
    }

    func send(_ request: HTTPTransportRequest) async throws(HTTPClientError) -> HTTPTransportResponse {
        // HTTPClient가 최종적으로 조립한 값을 그대로 남겨 URL, 헤더, 본문과 한도를 검증합니다.
        recordedRequests.append(request)
        // 계획하지 않은 추가 호출은 자동 재시도일 수 있으므로 connectionFailed로 드러냅니다.
        let behavior = behaviors.isEmpty ? .failure(.connectionFailed) : behaviors.removeFirst()

        switch behavior {
        case .response(let response):
            return response

        case .failure(let error):
            throw error

        case .suspended:
            await waitForCancellation()
            throw .cancelled

        case .waitForCancellation:
            await waitForCancellation()
            observedCancellationCount += 1
            throw .cancelled
        }
    }

    func waitUntilCalled(_ expectedCount: Int) async {
        // 테스트가 취소하기 전에 전송 작업이 실제로 시작됐음을 보장하는 동기화 지점입니다.
        while recordedRequests.count < expectedCount {
            await Task.yield()
        }
    }

    // MARK: Private

    private var behaviors: [Behavior]
    private var recordedRequests = [HTTPTransportRequest]()
    private var observedCancellationCount = 0

    private func waitForCancellation() async {
        // 벽시계 경쟁을 만들지 않습니다. 테스트가 먼저 취소를 관측 가능한 상태를 구성합니다.
        while !Task.isCancelled {
            await Task.yield()
        }
    }

}
