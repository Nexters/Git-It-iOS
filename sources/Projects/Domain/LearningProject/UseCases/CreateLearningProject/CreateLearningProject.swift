public struct CreateLearningProject: CreateLearningProjectUseCase {

    // MARK: Lifecycle

    public init(
        repository: LearningProjectRepository,
        creationStateRepository: RepositoryCreationStateRepository,
    ) {
        self.repository = repository
        self.creationStateRepository = creationStateRepository
    }

    // MARK: Public

    public func callAsFunction(
        githubRepoURL: String,
        quizLevel: QuizLevel,
    ) async throws -> ProjectRegistrationReceipt {
        guard await creationStateRepository.beginCreation(githubRepoURL: githubRepoURL) else {
            throw LearningProjectError.duplicateCreationInProgress
        }

        do {
            let receipt = try await repository.register(githubRepoURL: githubRepoURL, quizLevel: quizLevel)
            await creationStateRepository.attachProjectID(receipt.projectID, toGithubRepoURL: githubRepoURL)
            return receipt
        } catch {
            await creationStateRepository.endCreation(githubRepoURL: githubRepoURL)
            throw error
        }
    }

    // MARK: Private

    private let repository: LearningProjectRepository
    private let creationStateRepository: RepositoryCreationStateRepository

}
