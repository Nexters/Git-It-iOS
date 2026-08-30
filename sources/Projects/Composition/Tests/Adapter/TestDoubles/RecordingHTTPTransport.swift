import Foundation
import InfrastructureNetworkClient

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
