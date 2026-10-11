import DomainUseCaseInterface

public struct LearningSetResumption: Equatable, Sendable {

    // MARK: Lifecycle

    public init(set: QuizSet) {
        let quizzes = set.quizzes
        let firstUnanswered = quizzes.firstIndex { !Self.isAnswered($0) }

        startIndex = firstUnanswered ?? 0
        choiceQuestionCount = quizzes.count(where: { Self.isChoice($0) })
        skippedCorrectChoiceCount = quizzes.prefix(startIndex).count(where: {
            Self.isCorrectChoice($0)
        })
    }

    // MARK: Public

    public let startIndex: Int
    public let choiceQuestionCount: Int
    public let skippedCorrectChoiceCount: Int

    // MARK: Private

    private static func isAnswered(_ quiz: Quiz) -> Bool {
        switch quiz.content {
        case .choice(_, let submitted):
            submitted != nil

        case .essay(let submitted):
            submitted != nil
        }
    }

    private static func isChoice(_ quiz: Quiz) -> Bool {
        guard case .choice = quiz.content else { return false }
        return true
    }

    private static func isCorrectChoice(_ quiz: Quiz) -> Bool {
        guard case .choice(_, let submitted) = quiz.content else { return false }
        return submitted?.isCorrect == true
    }

}
