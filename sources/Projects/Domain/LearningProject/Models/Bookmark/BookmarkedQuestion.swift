public struct BookmarkedQuestion: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        projectID: String,
        projectName: String = "",
        setID: String,
        setLabel: String = "",
        problemNumber: Int = 0,
        questionID: String,
        prompt: String,
    ) {
        self.projectID = projectID
        self.projectName = projectName
        self.setID = setID
        self.setLabel = setLabel
        self.problemNumber = problemNumber
        self.questionID = questionID
        self.prompt = prompt
    }

    // MARK: Public

    public let projectID: String
    public let projectName: String
    public let setID: String
    public let setLabel: String
    public let problemNumber: Int
    public let questionID: String
    public let prompt: String

}
