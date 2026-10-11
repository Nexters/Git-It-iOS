import Foundation

// MARK: - TransportRequest

public struct TransportRequest: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        url: URL,
        headerFields: [String: String],
        body: Data?,
    ) {
        self.url = url
        self.headerFields = headerFields
        self.body = body
    }

    // MARK: Public

    public let url: URL
    public let headerFields: [String: String]
    public let body: Data?

}
