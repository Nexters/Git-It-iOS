public struct ChoiceAnswerResult: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        correct: Bool,
        answerIndex: Int,
        explanation: String,
    ) {
        self.correct = correct
        self.answerIndex = answerIndex
        self.explanation = explanation
    }

    // MARK: Public

    public let correct: Bool
    public let answerIndex: Int
    public let explanation: String

}
