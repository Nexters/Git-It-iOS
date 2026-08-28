import Foundation

public struct LegalAcceptanceRecord: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        documentIdentifier: String,
        version: String,
        acceptedAt: Date,
    ) {
        self.documentIdentifier = documentIdentifier
        self.version = version
        self.acceptedAt = acceptedAt
    }

    // MARK: Public

    public let documentIdentifier: String
    public let version: String
    public let acceptedAt: Date

}
