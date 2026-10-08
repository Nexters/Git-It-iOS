public struct ProjectGenerationReceipt: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        projectID: ProjectID,
        quizLevel: QuizLevel,
    ) {
        self.projectID = projectID
        self.quizLevel = quizLevel
    }

    // MARK: Public

    public let projectID: ProjectID
    public let quizLevel: QuizLevel

}
