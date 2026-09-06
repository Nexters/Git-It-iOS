import DomainLearningProject

public struct LearningSetResumption: Equatable, Sendable {

    // MARK: Lifecycle

    public init(set: LearningSet) {
        let questions = set.questions
        let firstUnanswered = questions.firstIndex { $0.myAnswer == nil }

        startIndex = firstUnanswered ?? 0
        choiceQuestionCount = questions.count(where: { $0.format == .multipleChoice })
        skippedCorrectChoiceCount = questions.prefix(startIndex).count(where: {
            $0.format == .multipleChoice && $0.myAnswer?.correct == true
        })
    }

    // MARK: Public

    public let startIndex: Int
    public let choiceQuestionCount: Int
    public let skippedCorrectChoiceCount: Int

}
