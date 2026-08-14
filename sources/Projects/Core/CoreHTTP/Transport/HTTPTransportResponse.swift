import Foundation

// MARK: - HTTPTransportResponse

public struct HTTPTransportResponse: Sendable {

    // MARK: Lifecycle

    public init(statusCode: Int, headers: HTTPHeaders, body: Data) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
    }

    // MARK: Public

    public let statusCode: Int
    public let headers: HTTPHeaders
    public let body: Data
}
