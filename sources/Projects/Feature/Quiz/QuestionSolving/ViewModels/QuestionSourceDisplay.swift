import DomainQuizDetail
import Foundation

// MARK: - QuestionSourceDisplay

public struct QuestionSourceDisplay: Equatable, Sendable, Identifiable {

    // MARK: Lifecycle

    public init(
        id: Int,
        title: String,
        detail: String?,
        lineAnchor: String?,
        summary: String?,
        referenceURL: URL?,
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.lineAnchor = lineAnchor
        self.summary = summary
        self.referenceURL = referenceURL
    }

    // MARK: Public

    public let id: Int
    public let title: String
    public let detail: String?
    public let lineAnchor: String?
    public let summary: String?
    public let referenceURL: URL?

    public var linkLabel: String {
        guard let lineAnchor else { return title }
        return "\(title):\(lineAnchor)"
    }

    public var isLink: Bool {
        referenceURL != nil
    }

    public var accessibilityLabel: String {
        var parts = [title]
        if let detail {
            parts.append(detail)
        }
        if let summary {
            parts.append(summary)
        }
        if isLink {
            parts.append(LocalizedText.Quiz.questionSourceLinkLabel)
        }
        return parts.joined(separator: ", ")
    }

    public static func list(sources: [QuizSource]) -> [Self] {
        sources.enumerated().map { index, source in
            Self(
                id: index,
                title: title(for: source),
                detail: lineRange(for: source),
                lineAnchor: lineAnchor(for: source),
                summary: source.summary,
                referenceURL: source.referenceURL.flatMap(URL.init(string:)),
            )
        }
    }

    // MARK: Private

    private static func title(for source: QuizSource) -> String {
        source.filePath ?? source.symbol ?? source.referenceURL ?? source.summary ?? LocalizedText.Quiz.questionSourceDefaultTitle
    }

    private static func lineRange(for source: QuizSource) -> String? {
        switch (source.startLine, source.endLine) {
        case (let start?, let end?):
            LocalizedText.Quiz.questionSourceLineRange(
                start: start,
                end: end,
            )

        case (let start?, nil):
            LocalizedText.Quiz.questionSourceStartLine(start: start)

        case (nil, let end?):
            LocalizedText.Quiz.questionSourceEndLine(end: end)

        case (nil, nil):
            nil
        }
    }

    private static func lineAnchor(for source: QuizSource) -> String? {
        switch (source.startLine, source.endLine) {
        case (let start?, let end?) where start != end:
            "L\(start)-L\(end)"

        case (let start?, _):
            "L\(start)"

        case (nil, let end?):
            "L\(end)"

        case (nil, nil):
            nil
        }
    }

}
