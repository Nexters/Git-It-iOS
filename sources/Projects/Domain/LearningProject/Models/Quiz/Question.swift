public struct Question: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        questionID: String,
        prompt: String,
        format: QuestionFormat,
        choices: [String]?,
        sources: [QuestionSource],
        myAnswer: SubmittedAnswer?,
    ) {
        self.questionID = questionID
        self.prompt = prompt
        self.format = format
        self.choices = choices
        self.sources = sources
        self.myAnswer = myAnswer
    }

    // MARK: Public

    public let questionID: String
    public let prompt: String
    public let format: QuestionFormat
    public let choices: [String]?
    public let sources: [QuestionSource]
    public let myAnswer: SubmittedAnswer?

}
