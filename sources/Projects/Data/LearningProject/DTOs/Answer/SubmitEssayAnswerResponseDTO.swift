public struct SubmitEssayAnswerResponseDTO: Decodable, Equatable, Sendable {
    public init(
        questionID: String,
        explanation: String,
        rubric: RubricResponseDTO,
    ) {
        self.questionID = questionID
        self.explanation = explanation
        self.rubric = rubric
    }

    public let questionID: String
    public let explanation: String
    public let rubric: RubricResponseDTO

    private enum CodingKeys: String, CodingKey {
        case questionID = "questionId"
        case explanation
        case rubric
    }
}
