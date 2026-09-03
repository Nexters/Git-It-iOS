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
    /// 서버 응답 순서를 그대로 보존합니다. 출처가 없는 문제는 빈 배열입니다.
    public let sources: [QuestionSource]
    /// 이전에 제출한 답변. 제출한 적이 없으면 비어 있습니다.
    public let myAnswer: SubmittedAnswer?

}
