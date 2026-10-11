// MARK: - RequestTransport

public protocol RequestTransport: Sendable {
    func send(_ request: TransportRequest) async throws(RequestTransportError) -> TransportResponse
}
