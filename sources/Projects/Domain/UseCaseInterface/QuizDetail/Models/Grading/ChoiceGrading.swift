public struct ChoiceGrading: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        isCorrect: Bool,
        correctIndex: Int,
        explanation: String,
    ) {
        self.isCorrect = isCorrect
        self.correctIndex = correctIndex
        self.explanation = explanation
    }

    // MARK: Public

    public let isCorrect: Bool
    public let correctIndex: Int
    public let explanation: String

}
