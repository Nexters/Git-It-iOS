public struct ProjectSetProgress: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        setID: QuizSetID,
        label: String,
        title: String,
        quizCount: Int,
        completedCount: Int,
    ) {
        self.setID = setID
        self.label = label
        self.title = title
        self.quizCount = quizCount
        self.completedCount = completedCount
    }

    // MARK: Public

    public let setID: QuizSetID
    public let label: String
    public let title: String
    public let quizCount: Int
    public let completedCount: Int

}
