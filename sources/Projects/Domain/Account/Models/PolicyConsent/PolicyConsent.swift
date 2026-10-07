import Foundation

public struct PolicyConsent: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        documentID: PolicyDocumentID,
        version: String,
        consentedAt: Date,
    ) {
        self.documentID = documentID
        self.version = version
        self.consentedAt = consentedAt
    }

    // MARK: Public

    public let documentID: PolicyDocumentID
    public let version: String
    public let consentedAt: Date

}
