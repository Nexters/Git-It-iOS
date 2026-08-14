import Foundation

// MARK: - HTTPTransportRequest

public struct HTTPTransportRequest: Sendable {

    // MARK: Public

    public let url: URL
    public let method: HTTPMethod
    public let headers: HTTPHeaders
    public let body: Data?
    public let responseTimeout: Duration

}
