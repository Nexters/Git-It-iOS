import Foundation

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
