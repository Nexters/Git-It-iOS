import Foundation

public struct CreateLearningProject: CreateLearningProjectUseCase {

    // MARK: Lifecycle

    public init(
        repository: LearningProjectRepository,
        pendingGenerations: any PendingGenerationRepository,
        now: @escaping @Sendable () -> Date = Date.init,
    ) {
        self.repository = repository
        self.pendingGenerations = pendingGenerations
        self.now = now
    }

    // MARK: Public

    public func callAsFunction(
        githubRepoURL: String,
        quizLevel: QuizLevel,
    ) async throws -> ProjectRegistrationReceipt {
        guard await pendingGenerations.beginGeneration(githubRepoURL: githubRepoURL, requestedAt: now()) else {
            throw LearningProjectError.duplicateCreationInProgress
        }

        do {
            let receipt = try await repository.register(githubRepoURL: githubRepoURL, quizLevel: quizLevel)
            await pendingGenerations.attachProjectID(receipt.projectID, toGithubRepoURL: githubRepoURL)
            return receipt
        } catch {
            await pendingGenerations.releaseGeneration(githubRepoURL: githubRepoURL)
            throw error
        }
    }

    // MARK: Private

    private let repository: LearningProjectRepository
    private let pendingGenerations: any PendingGenerationRepository
    private let now: @Sendable () -> Date

}
