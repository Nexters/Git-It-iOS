public struct LearningProjectRegistration: Equatable, Sendable {
    public init(
        projectId: String,
        status: QuizGenerationStatus,
        quizLevel: QuizLevel,
    ) {
        self.projectId = projectId
        self.status = status
        self.quizLevel = quizLevel
    }

    public let projectId: String
    public let status: QuizGenerationStatus
    public let quizLevel: QuizLevel
}
