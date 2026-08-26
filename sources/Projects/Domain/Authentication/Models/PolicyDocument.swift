import Foundation

public struct PolicyDocument: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        identifier: String,
        displayName: String,
        version: String,
        approvedURL: URL,
        isRequired: Bool,
    ) {
        self.identifier = identifier
        self.displayName = displayName
        self.version = version
        self.approvedURL = approvedURL
        self.isRequired = isRequired
    }

    // MARK: Public

    public let identifier: String
    public let displayName: String
    public let version: String
    public let approvedURL: URL
    public let isRequired: Bool

}
