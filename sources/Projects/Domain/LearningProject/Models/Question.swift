/// 정답·해설·rubric은 제출 전 공개하지 않는다. `myAnswer`가 nil이면 아직 응답 전이다.
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
    /// 객관식일 때만 값을 가진다.
    public let choices: [String]?
    public let source: QuestionSource
    public let myAnswer: String?

}
