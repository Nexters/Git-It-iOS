public struct Question: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        questionID: String,
        prompt: String,
        format: QuestionFormat,
        choices: [String]?,
        source: QuestionSource,
        myAnswer: String?,
    ) {
        self.questionID = questionID
        self.prompt = prompt
        self.format = format
        self.choices = choices
        self.source = source
        self.myAnswer = myAnswer
    }

    // MARK: Public

    public let questionID: String
    public let prompt: String
    public let format: QuestionFormat
    public let choices: [String]?
    public let source: QuestionSource
    public let myAnswer: String?

}
