public protocol CreateLearningProjectUseCase: Sendable {
    func callAsFunction(
        githubRepoUrl: String,
        quizLevel: QuizLevel,
    ) async throws -> LearningProjectRegistration
}
