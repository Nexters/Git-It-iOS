import Foundation

public struct SourceResponseDTO: Decodable, Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        file: String,
        startLine: Int,
        endLine: Int,
        symbol: String,
        summary: String?,
        url: String,
    ) {
        self.file = file
        self.startLine = startLine
        self.endLine = endLine
        self.symbol = symbol
        self.summary = summary
        self.url = url
    }

    // MARK: Public

    public let file: String
    public let startLine: Int
    public let endLine: Int
    public let symbol: String
    public let summary: String?
    public let url: String

}
