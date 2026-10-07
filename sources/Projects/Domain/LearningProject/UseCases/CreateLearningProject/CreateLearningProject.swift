import Foundation

public struct CreateLearningProject: CreateLearningProjectUseCase {

    // MARK: Lifecycle

    public init(
        repository: LearningProjectRepository,
        trackGeneration: any TrackGenerationUseCase,
        now: @escaping @Sendable () -> Date = Date.init,
    ) {
        self.repository = repository
        self.trackGeneration = trackGeneration
        self.now = now
    }

    // MARK: Public

    public func callAsFunction(
        githubRepoURL: String,
        quizLevel: QuizLevel,
    ) async throws -> ProjectRegistrationReceipt {
        guard await trackGeneration.begin(githubRepoURL: githubRepoURL, requestedAt: now()) else {
            throw LearningProjectError.duplicateCreationInProgress
        }

        do {
            let receipt = try await repository.register(githubRepoURL: githubRepoURL, quizLevel: quizLevel)
            await trackGeneration.attachProjectID(receipt.projectID, toGithubRepoURL: githubRepoURL)
            return receipt
        } catch {
            await trackGeneration.end(githubRepoURL: githubRepoURL)
            throw error
        }
    }

    // MARK: Private

    private let repository: LearningProjectRepository
    private let trackGeneration: any TrackGenerationUseCase
    private let now: @Sendable () -> Date

}
