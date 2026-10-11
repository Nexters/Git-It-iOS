public struct QuizBookmarkState: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        quizID: QuizID,
        isBookmarked: Bool,
    ) {
        self.quizID = quizID
        self.isBookmarked = isBookmarked
    }

    // MARK: Public

    public let quizID: QuizID
    public let isBookmarked: Bool

}
