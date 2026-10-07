import DomainIdentifier
import DomainQuizDetail
import Foundation

// MARK: - SavedQuestionDisplay

public struct SavedQuestionDisplay: Equatable, Sendable, Identifiable {

    // MARK: Lifecycle

    public init(
        id: QuizID,
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

    public static let actionTitle = "문제풀기"

    public let id: QuizID
    public let metadata: String
    public let prompt: String
    public let isBookmarked: Bool

    public static func list(
        questions: [QuizBookmark],
        bookmarkOverrides: [QuizID: Bool] = [:],
    ) -> [Self] {
        questions.map {
            Self(
                id: $0.quizID,
                metadata: "\($0.projectName) · \($0.setLabel) · 문제 \($0.problemNumber)",
                prompt: $0.prompt,
                isBookmarked: bookmarkOverrides[$0.quizID] ?? true,
            )
        }
    }

}
