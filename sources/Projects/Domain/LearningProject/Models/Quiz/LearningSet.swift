public struct LearningSet: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        setID: String,
        title: String,
        description: String,
        questions: [Question],
    ) {
        self.setID = setID
        self.title = title
        self.description = description
        self.questions = questions
    }

    // MARK: Public

    public let setID: String
    public let title: String
    public let description: String
    public let questions: [Question]

}
