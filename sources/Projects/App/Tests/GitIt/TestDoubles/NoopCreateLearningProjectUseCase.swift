import DomainLearningProject
import Foundation

struct NoopCreateLearningProjectUseCase: CreateLearningProjectUseCase {
    func callAsFunction(
        githubRepoURL _: String,
        quizLevel _: QuizLevel,
    ) async throws -> ProjectRegistrationReceipt {
        throw CancellationError()
    }
}
