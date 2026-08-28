public struct ProjectRegistrationReceipt: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        projectID: String,
        requestStatus: String,
        quizLevel: QuizLevel,
    ) {
        self.projectID = projectID
        self.requestStatus = requestStatus
        self.quizLevel = quizLevel
    }

    // MARK: Public

    public let projectID: String
    public let requestStatus: String
    public let quizLevel: QuizLevel

}
