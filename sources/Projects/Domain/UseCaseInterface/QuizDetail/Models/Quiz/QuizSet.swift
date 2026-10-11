public struct QuizSet: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        id: QuizSetID,
        title: String,
        description: String,
        quizzes: [Quiz],
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.quizzes = quizzes
    }

    // MARK: Public

    public let id: QuizSetID
    public let title: String
    public let description: String
    public let quizzes: [Quiz]

}
