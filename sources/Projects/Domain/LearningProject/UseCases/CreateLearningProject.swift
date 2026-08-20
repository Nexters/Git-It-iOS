public struct CreateLearningProject: CreateLearningProjectUseCase {

    // MARK: Lifecycle

    public init(repository: LearningProjectRepository) {
        self.repository = repository
    }

    // MARK: Public

    public func callAsFunction(
        githubRepoUrl: String,
        quizLevel: QuizLevel,
    ) async throws -> LearningProjectRegistration {
        try await repository.register(githubRepoUrl: githubRepoUrl, quizLevel: quizLevel)
    }

    // MARK: Private

    private let repository: LearningProjectRepository

}
