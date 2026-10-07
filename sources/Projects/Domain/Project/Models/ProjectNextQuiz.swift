import DomainIdentifier

public struct ProjectNextQuiz: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        setID: QuizSetID,
        quizID: QuizID?,
    ) {
        self.setID = setID
        self.quizID = quizID
    }

    // MARK: Public

    public let setID: QuizSetID
    public let quizID: QuizID?

}
