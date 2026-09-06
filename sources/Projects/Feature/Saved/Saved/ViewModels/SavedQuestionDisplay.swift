import DomainLearningProject
import Foundation

// MARK: - SavedQuestionDisplay

/// 저장한 문제 항목의 표시 값입니다. 세트 제목·라벨을 위해 추가 조회를 하지 않습니다.
public struct SavedQuestionDisplay: Equatable, Sendable, Identifiable {

    // MARK: Lifecycle

    public init(
        id: String,
        metadata: String,
        prompt: String,
        isBookmarked: Bool,
    ) {
        self.id = id
        self.metadata = metadata
        self.prompt = prompt
        self.isBookmarked = isBookmarked
    }

    // MARK: Public

    /// 목록 항목의 진입 컨트롤 문구입니다.
    public static let actionTitle = "문제풀기"

    public let id: String
    /// `{프로젝트명} · {세트 라벨} · 문제 {번호}` 형식의 카드 상단 보조 문구입니다.
    public let metadata: String
    public let prompt: String
    public let isBookmarked: Bool

    public static func list(
        questions: [BookmarkedQuestion],
        bookmarkOverrides: [String: Bool] = [:],
    ) -> [Self] {
        questions.map {
            Self(
                id: $0.questionID,
                metadata: "\($0.projectName) · \($0.setLabel) · 문제 \($0.problemNumber)",
                prompt: $0.prompt,
                isBookmarked: bookmarkOverrides[$0.questionID] ?? true,
            )
        }
    }

}
