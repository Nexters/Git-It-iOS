import DomainIdentifier

public struct EssayAnswer: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        projectID: ProjectID,
        quizID: QuizID,
        text: String,
    ) {
        self.projectID = projectID
        self.quizID = quizID
        self.text = text
    }

    // MARK: Public

    public let projectID: ProjectID
    public let quizID: QuizID
    public let text: String

}
