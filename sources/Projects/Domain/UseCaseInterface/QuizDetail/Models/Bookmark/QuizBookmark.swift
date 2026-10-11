public struct QuizBookmark: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        projectID: ProjectID,
        projectName: String,
        setID: QuizSetID,
        setLabel: String,
        problemNumber: Int,
        quizID: QuizID,
        prompt: String,
    ) {
        self.projectID = projectID
        self.projectName = projectName
        self.setID = setID
        self.setLabel = setLabel
        self.problemNumber = problemNumber
        self.quizID = quizID
        self.prompt = prompt
    }

    // MARK: Public

    public let projectID: ProjectID
    public let projectName: String
    public let setID: QuizSetID
    public let setLabel: String
    public let problemNumber: Int
    public let quizID: QuizID
    public let prompt: String

}
