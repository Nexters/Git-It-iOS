import InfrastructureNetworkClient

// MARK: - RequestTransportBridge

package struct RequestTransportBridge: HTTPTransport {

    // MARK: Lifecycle

    package init(transport: any RequestTransport) {
        self.transport = transport
    }

    // MARK: Package

    package func send(_ request: HTTPTransportRequest) async throws(HTTPClientError) -> HTTPTransportResponse {
        var headerFields = [String: String]()
        for (name, value) in request.headers.all {
            headerFields[name] = value
        }
        do {
            let response = try await transport.send(
                TransportRequest(url: request.url, headerFields: headerFields, body: request.body)
            )
            var headers = HTTPHeaders()
            for (name, value) in response.headerFields {
                headers[name] = value
            }
            return HTTPTransportResponse(statusCode: response.statusCode, headers: headers, body: response.body)
        } catch {
            throw Self.clientError(for: error)
        }
    }

    // MARK: Private

    private let transport: any RequestTransport

    private static func clientError(for error: RequestTransportError) -> HTTPClientError {
        switch error {
        case .cancelled:
            .cancelled

        case .timedOut:
            .timedOut

        case .connectionFailed:
            .connectionFailed
        }
    }

}
