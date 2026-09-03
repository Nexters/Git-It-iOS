public struct QuestionSource: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        filePath: String?,
        startLine: Int?,
        endLine: Int?,
        symbol: String?,
        summary: String?,
        referenceURL: String?,
    ) {
        self.filePath = filePath
        self.startLine = startLine
        self.endLine = endLine
        self.symbol = symbol
        self.summary = summary
        self.referenceURL = referenceURL
    }

    // MARK: Public

    public let filePath: String?
    public let startLine: Int?
    public let endLine: Int?
    public let symbol: String?
    public let summary: String?
    public let referenceURL: String?

}
