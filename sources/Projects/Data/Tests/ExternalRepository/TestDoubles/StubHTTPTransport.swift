import Foundation
import InfrastructureNetworkClient

actor StubHTTPTransport: HTTPTransport {

    // MARK: Lifecycle

    init(results: [ScriptedResult]) {
        self.results = results
    }

    // MARK: Internal

    enum ScriptedResult: Sendable {
        case response(HTTPTransportResponse)
        case failure(HTTPClientError)
    }

    private(set) var recordedRequests = [HTTPTransportRequest]()

    func send(_ request: HTTPTransportRequest) async throws(HTTPClientError) -> HTTPTransportResponse {
        recordedRequests.append(request)
        guard !results.isEmpty else { throw .connectionFailed }
        switch results.removeFirst() {
        case .response(let response):
            return response

        case .failure(let error):
            throw error
        }
    }

    // MARK: Private

    private var results: [ScriptedResult]

}
