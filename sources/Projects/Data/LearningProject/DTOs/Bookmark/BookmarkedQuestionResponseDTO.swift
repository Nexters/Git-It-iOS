public struct BookmarkedQuestionResponseDTO: Decodable, Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        projectID: String,
        projectName: String = "",
        setID: String,
        setLabel: String = "",
        problemNumber: Int = 0,
        questionID: String,
        question: String = "",
    ) {
        self.projectID = projectID
        self.projectName = projectName
        self.setID = setID
        self.setLabel = setLabel
        self.problemNumber = problemNumber
        self.questionID = questionID
        self.question = question
    }

    // MARK: Public

    public let projectID: String
    public let projectName: String
    public let setID: String
    public let setLabel: String
    public let problemNumber: Int
    public let questionID: String
    public let question: String

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case projectID = "projectId"
        case projectName
        case setID = "setId"
        case setLabel
        case problemNumber
        case questionID = "questionId"
        case question
    }

}
