public struct BookmarkedQuestion: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        projectID: String,
        setID: String,
        questionID: String,
        prompt: String,
    ) {
        self.projectID = projectID
        self.setID = setID
        self.questionID = questionID
        self.prompt = prompt
    }

    // MARK: Public

    public let projectID: String
    public let setID: String
    public let questionID: String
    public let prompt: String

}
