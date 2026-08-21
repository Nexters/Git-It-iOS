public protocol CreateLearningProjectUseCase: Sendable {
    func callAsFunction(
        githubRepoURL: String,
        quizLevel: QuizLevel,
    ) async throws -> ProjectRegistrationReceipt
}
