import DataShared
import Foundation

actor RecordingRequestTransport: RequestTransport {

    // MARK: Lifecycle

    init(results: [TransportResponse]) {
        self.results = results
    }

    // MARK: Internal

    private(set) var recordedRequests = [TransportRequest]()

    func send(_ request: TransportRequest) async throws(RequestTransportError) -> TransportResponse {
        recordedRequests.append(request)
        guard !results.isEmpty else { throw .connectionFailed }
        return results.removeFirst()
    }

    // MARK: Private

    private var results: [TransportResponse]

}
