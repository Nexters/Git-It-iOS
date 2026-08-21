public struct CreateLearningProject: CreateLearningProjectUseCase {

    // MARK: Lifecycle

    public init(repository: LearningProjectRepository) {
        self.repository = repository
    }

    // MARK: Public

    public func callAsFunction(
        githubRepoURL: String,
        quizLevel: QuizLevel,
    ) async throws -> ProjectRegistrationReceipt {
        try await repository.register(githubRepoURL: githubRepoURL, quizLevel: quizLevel)
    }

    // MARK: Private

    private let repository: LearningProjectRepository

}
