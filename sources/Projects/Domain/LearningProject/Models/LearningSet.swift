public struct LearningSet: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        setID: String,
        title: String,
        questions: [Question],
    ) {
        self.setID = setID
        self.title = title
        self.questions = questions
    }

    // MARK: Public

    public let setID: String
    public let title: String
    public let questions: [Question]

}
