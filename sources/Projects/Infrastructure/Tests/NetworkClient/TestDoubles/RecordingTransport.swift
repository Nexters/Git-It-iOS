import Foundation

@testable import InfrastructureNetworkClient

actor RecordingTransport: HTTPTransport {

    // MARK: Lifecycle

    init(_ behaviors: [Behavior]) {
        self.behaviors = behaviors
    }

    // MARK: Internal

    enum Behavior: Sendable {
        case response(HTTPTransportResponse)
        case failure(HTTPClientError)
        case suspended
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
        recordedRequests.append(request)
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
        while recordedRequests.count < expectedCount {
            await Task.yield()
        }
    }

    // MARK: Private

    private var behaviors: [Behavior]
    private var recordedRequests = [HTTPTransportRequest]()
    private var observedCancellationCount = 0

    private func waitForCancellation() async {
        while !Task.isCancelled {
            await Task.yield()
        }
    }

}
