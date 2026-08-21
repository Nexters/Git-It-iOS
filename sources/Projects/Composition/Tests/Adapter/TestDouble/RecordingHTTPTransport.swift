import Foundation
import InfrastructureNetworkClient

/// `AppComposition.live`에 주입해 실제 네트워크 없이 요청을 관찰하는 stub transport입니다.
actor RecordingHTTPTransport: HTTPTransport {

    // MARK: Lifecycle

    init(results: [HTTPTransportResponse]) {
        self.results = results
    }

    // MARK: Internal

    private(set) var recordedRequests = [HTTPTransportRequest]()

    func send(_ request: HTTPTransportRequest) async throws(HTTPClientError) -> HTTPTransportResponse {
        recordedRequests.append(request)
        guard !results.isEmpty else { throw .connectionFailed }
        return results.removeFirst()
    }

    // MARK: Private

    private var results: [HTTPTransportResponse]

}
