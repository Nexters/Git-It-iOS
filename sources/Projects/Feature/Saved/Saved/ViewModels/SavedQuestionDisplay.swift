import DomainLearningProject
import Foundation

// MARK: - SavedQuestionDisplay

/// 저장한 문제 항목의 표시 값입니다. 세트 제목·라벨을 위해 추가 조회를 하지 않습니다.
public struct SavedQuestionDisplay: Equatable, Sendable, Identifiable {

    // MARK: Lifecycle

    public init(
        id: String,
        prompt: String,
    ) {
        self.id = id
        self.prompt = prompt
    }

    // MARK: Public

    /// 목록 항목의 진입 컨트롤 문구입니다.
    public static let actionTitle = "문제 풀기"

    public let id: String
    public let prompt: String

    public static func list(questions: [BookmarkedQuestion]) -> [Self] {
        questions.map { Self(id: $0.questionID, prompt: $0.prompt) }
    }

}
