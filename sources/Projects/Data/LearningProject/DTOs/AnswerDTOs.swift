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
        self.init(
            criteria: [RubricCriterionResponseDTO(text: feedback, points: score)],
            keyPoints: [],
            fullMarkExample: "",
            partialExample: "",
            zeroExample: "",
        )
    }

    public init(
        criteria: [RubricCriterionResponseDTO],
        keyPoints: [String],
        fullMarkExample: String,
        partialExample: String,
        zeroExample: String,
    ) {
        self.criteria = criteria
        self.keyPoints = keyPoints
        self.fullMarkExample = fullMarkExample
        self.partialExample = partialExample
        self.zeroExample = zeroExample
    }

    public let criteria: [RubricCriterionResponseDTO]
    public let keyPoints: [String]
    public let fullMarkExample: String
    public let partialExample: String
    public let zeroExample: String

    public var feedback: String {
        criteria.map(\.text).joined(separator: "\n")
    }
}

// MARK: - RubricCriterionResponseDTO

public struct RubricCriterionResponseDTO: Decodable, Equatable, Sendable {
    public init(
        text: String,
        points: Int,
    ) {
        self.text = text
        self.points = points
    }

    public let text: String
    public let points: Int
}
