public struct SubmitChoiceAnswerResponseDTO: Decodable, Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        questionID: String,
        correct: Bool,
        answerIndex: Int,
        explanation: String,
    ) {
        self.questionID = questionID
        self.correct = correct
        self.answerIndex = answerIndex
        self.explanation = explanation
    }

    // MARK: Public

    public let questionID: String
    public let correct: Bool
    public let answerIndex: Int
    public let explanation: String

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case questionID = "questionId"
        case correct
        case answerIndex
        case explanation
    }

}
