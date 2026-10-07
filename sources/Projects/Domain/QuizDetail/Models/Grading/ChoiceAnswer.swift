import DomainIdentifier

public struct ChoiceAnswer: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        projectID: ProjectID,
        quizID: QuizID,
        selectedIndex: Int,
    ) {
        self.projectID = projectID
        self.quizID = quizID
        self.selectedIndex = selectedIndex
    }

    // MARK: Public

    public let projectID: ProjectID
    public let quizID: QuizID
    public let selectedIndex: Int

}
