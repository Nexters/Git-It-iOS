import DomainLearningProject
import Foundation

// MARK: - ProjectDetailSetDisplay

/// 프로젝트 상세의 세트 항목 표시 값입니다.
public struct ProjectDetailSetDisplay: Equatable, Sendable, Identifiable {

    // MARK: Lifecycle

    public init(
        id: String,
        label: String,
        title: String,
        questionCount: Int,
        completedCount: Int,
    ) {
        self.id = id
        self.label = label
        self.title = title
        self.questionCount = questionCount
        self.completedCount = completedCount
    }

    // MARK: Public

    public let id: String
    public let label: String
    public let title: String
    public let questionCount: Int
    public let completedCount: Int

    public var isCompleted: Bool {
        questionCount > 0 && completedCount >= questionCount
    }

    public static func list(sets: [LearningProjectSetProgress]) -> [Self] {
        sets.map {
            Self(
                id: $0.setID,
                label: $0.label,
                title: $0.title,
                questionCount: $0.problemCount,
                completedCount: $0.completedCount,
            )
        }
    }

}
