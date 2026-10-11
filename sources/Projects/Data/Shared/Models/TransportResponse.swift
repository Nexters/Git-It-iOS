import Foundation

// MARK: - TransportResponse

public struct TransportResponse: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        statusCode: Int,
        headerFields: [String: String] = [:],
        body: Data,
    ) {
        self.statusCode = statusCode
        self.headerFields = headerFields
        self.body = body
    }

    // MARK: Public

    public let statusCode: Int
    public let headerFields: [String: String]
    public let body: Data

}
