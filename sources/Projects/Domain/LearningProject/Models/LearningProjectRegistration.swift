public struct LearningProjectRegistration: Equatable, Sendable {
    public init(
        projectID: String,
        status: QuizGenerationStatus,
        quizLevel: QuizLevel,
    ) {
        self.projectID = projectID
        self.status = status
        self.quizLevel = quizLevel
    }

    public let projectID: String
    public let status: QuizGenerationStatus
    public let quizLevel: QuizLevel
}
