// MARK: - SubmitChoiceAnswerRequestDTO

public struct SubmitChoiceAnswerRequestDTO: Encodable, Equatable, Sendable {
    public init(selectedIndex: Int) {
        self.selectedIndex = selectedIndex
    }

    public let selectedIndex: Int
}

// MARK: - SubmitChoiceAnswerResponseDTO

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

// MARK: - SubmitEssayAnswerRequestDTO

public struct SubmitEssayAnswerRequestDTO: Encodable, Equatable, Sendable {
    public init(text: String) {
        self.text = text
    }

    public let text: String
}

// MARK: - SubmitEssayAnswerResponseDTO

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

// MARK: - RubricResponseDTO

public struct RubricResponseDTO: Decodable, Equatable, Sendable {
    public init(
        score: Int,
        feedback: String,
    ) {
        self.score = score
        self.feedback = feedback
    }

    public let score: Int
    public let feedback: String
}
