import Foundation

// MARK: - LearningSetResponseDTO

public struct LearningSetResponseDTO: Decodable, Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        setID: String,
        title: String,
        description: String,
        orientation: String,
        level: String,
        questions: [QuestionResponseDTO],
    ) {
        self.setID = setID
        self.title = title
        self.description = description
        self.orientation = orientation
        self.level = level
        self.questions = questions
    }

    // MARK: Public

    public let setID: String
    public let title: String
    public let description: String
    public let orientation: String
    public let level: String
    public let questions: [QuestionResponseDTO]

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case setID = "setId"
        case title
        case description
        case orientation
        case level
        case questions
    }

}

// MARK: - QuestionResponseDTO

public struct QuestionResponseDTO: Decodable, Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        questionID: String,
        format: String,
        text: String,
        choices: [String],
        sources: [SourceResponseDTO],
        myAnswer: MyAnswerResponseDTO?,
    ) {
        self.questionID = questionID
        self.format = format
        self.text = text
        self.choices = choices
        self.sources = sources
        self.myAnswer = myAnswer
    }

    // MARK: Public

    public let questionID: String
    public let format: String
    public let text: String
    public let choices: [String]
    public let sources: [SourceResponseDTO]
    public let myAnswer: MyAnswerResponseDTO?

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case questionID = "questionId"
        case format
        case text
        case choices
        case sources
        case myAnswer
    }

}

// MARK: - SourceResponseDTO

public struct SourceResponseDTO: Decodable, Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        file: String,
        startLine: Int,
        endLine: Int,
        symbol: String,
        summary: String?,
        url: String,
    ) {
        self.file = file
        self.startLine = startLine
        self.endLine = endLine
        self.symbol = symbol
        self.summary = summary
        self.url = url
    }

    // MARK: Public

    public let file: String
    public let startLine: Int
    public let endLine: Int
    public let symbol: String
    public let summary: String?
    public let url: String

}

// MARK: - MyAnswerResponseDTO

public struct MyAnswerResponseDTO: Decodable, Equatable, Sendable {
    public init(
        selectedIndex: Int?,
        text: String?,
        correct: Bool?,
        answeredAt: Date,
    ) {
        self.selectedIndex = selectedIndex
        self.text = text
        self.correct = correct
        self.answeredAt = answeredAt
    }

    public let selectedIndex: Int?
    public let text: String?
    public let correct: Bool?
    public let answeredAt: Date
}
