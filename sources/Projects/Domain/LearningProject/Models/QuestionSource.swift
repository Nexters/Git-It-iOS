public struct QuestionSource: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        filePath: String?,
        referenceURL: String?,
    ) {
        self.filePath = filePath
        self.referenceURL = referenceURL
    }

    // MARK: Public

    public let filePath: String?
    public let referenceURL: String?

}
