// MARK: - HTTPTransport

public protocol HTTPTransport: Sendable {
    func send(_ request: HTTPTransportRequest) async throws(HTTPClientError) -> HTTPTransportResponse
}
