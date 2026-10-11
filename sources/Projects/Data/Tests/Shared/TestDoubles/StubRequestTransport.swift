import DataShared
import Foundation

// MARK: - StubRequestTransport

actor StubRequestTransport: RequestTransport {

    // MARK: Lifecycle

    init(result: Result<TransportResponse, RequestTransportError>) {
        self.result = result
    }

    // MARK: Internal

    private(set) var recordedRequests = [TransportRequest]()

    func send(_ request: TransportRequest) async throws(RequestTransportError) -> TransportResponse {
        recordedRequests.append(request)
        return try result.get()
    }

    // MARK: Private

    private let result: Result<TransportResponse, RequestTransportError>

}
