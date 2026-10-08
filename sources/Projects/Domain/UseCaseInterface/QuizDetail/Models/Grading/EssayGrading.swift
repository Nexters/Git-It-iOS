public struct EssayGrading: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        explanation: String,
        rubric: [String],
    ) {
        self.explanation = explanation
        self.rubric = rubric
    }

    // MARK: Public

    public let explanation: String
    public let rubric: [String]

}
