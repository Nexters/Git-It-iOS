public struct Quiz: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        id: QuizID,
        prompt: String,
        content: QuizContent,
        sources: [QuizSource],
    ) {
        self.id = id
        self.prompt = prompt
        self.content = content
        self.sources = sources
    }

    // MARK: Public

    public let id: QuizID
    public let prompt: String
    public let content: QuizContent
    public let sources: [QuizSource]

}
