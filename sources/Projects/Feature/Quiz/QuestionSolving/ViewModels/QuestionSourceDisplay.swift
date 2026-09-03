import DomainLearningProject
import Foundation

// MARK: - QuestionSourceDisplay

/// 출처 한 건의 표시 값입니다. 서브뷰는 Domain 모델을 받지 않습니다.
public struct QuestionSourceDisplay: Equatable, Sendable, Identifiable {

    // MARK: Lifecycle

    public init(
        id: Int,
        title: String,
        detail: String?,
        summary: String?,
        referenceURL: URL?,
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.summary = summary
        self.referenceURL = referenceURL
    }

    // MARK: Public

    public let id: Int
    public let title: String
    public let detail: String?
    public let summary: String?
    public let referenceURL: URL?

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
            parts.append("링크")
        }
        return parts.joined(separator: ", ")
    }

    /// 출처 배열 전체를 응답 순서 그대로 변환합니다.
    public static func list(sources: [QuestionSource]) -> [Self] {
        sources.enumerated().map { index, source in
            Self(
                id: index,
                title: title(for: source),
                detail: lineRange(for: source),
                summary: source.summary,
                referenceURL: source.referenceURL.flatMap(URL.init(string:)),
            )
        }
    }

    // MARK: Private

    private static func title(for source: QuestionSource) -> String {
        source.filePath ?? source.symbol ?? source.referenceURL ?? source.summary ?? "출처"
    }

    private static func lineRange(for source: QuestionSource) -> String? {
        switch (source.startLine, source.endLine) {
        case (let start?, let end?):
            "\(start)–\(end)행"

        case (let start?, nil):
            "\(start)행"

        case (nil, let end?):
            "\(end)행"

        case (nil, nil):
            nil
        }
    }

}
