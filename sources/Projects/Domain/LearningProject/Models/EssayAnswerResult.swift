public struct EssayAnswerResult: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        explanation: String,
        rubric: Rubric,
    ) {
        self.explanation = explanation
        self.rubric = rubric
    }

    // MARK: Public

    public let explanation: String
    public let rubric: Rubric

}
