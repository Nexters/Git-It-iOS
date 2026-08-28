import Foundation

public struct PolicyConsentRecord: Equatable, Sendable {

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

    public static func isConsentValid(
        storedRecords: [PolicyConsentRecord],
        for requiredDocuments: [PolicyDocument],
    ) -> Bool {
        requiredDocuments.allSatisfy { document in
            guard document.isRequired else { return true }
            return storedRecords.contains {
                $0.documentIdentifier == document.identifier && $0.version == document.version
            }
        }
    }

}
