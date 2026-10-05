import Foundation

public struct PolicyDocument: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        id: PolicyDocumentID,
        displayName: String,
        version: String,
        approvedURL: URL,
        isRequired: Bool,
    ) {
        self.id = id
        self.displayName = displayName
        self.version = version
        self.approvedURL = approvedURL
        self.isRequired = isRequired
    }

    // MARK: Public

    public let id: PolicyDocumentID
    public let displayName: String
    public let version: String
    public let approvedURL: URL
    public let isRequired: Bool

}
