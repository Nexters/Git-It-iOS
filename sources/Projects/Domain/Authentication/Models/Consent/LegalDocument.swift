public struct LegalDocument: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        identifier: String,
        version: String,
        title: String,
        contentURL: String,
        isRequired: Bool,
    ) {
        self.identifier = identifier
        self.version = version
        self.title = title
        self.contentURL = contentURL
        self.isRequired = isRequired
    }

    // MARK: Public

    public let identifier: String
    public let version: String
    public let title: String
    public let contentURL: String
    public let isRequired: Bool

}
