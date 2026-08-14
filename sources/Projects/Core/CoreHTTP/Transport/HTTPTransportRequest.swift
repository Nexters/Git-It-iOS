import Foundation

// MARK: - HTTPTransportRequest

public struct HTTPTransportRequest: Sendable {

    // MARK: Lifecycle

    init(
        url: URL,
        method: HTTPMethod,
        headers: HTTPHeaders,
        body: Data?,
        responseTimeout: Duration,
    ) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
        self.responseTimeout = responseTimeout
    }

    // MARK: Public

    public let url: URL
    public let method: HTTPMethod
    public let headers: HTTPHeaders
    public let body: Data?
    public let responseTimeout: Duration
}
