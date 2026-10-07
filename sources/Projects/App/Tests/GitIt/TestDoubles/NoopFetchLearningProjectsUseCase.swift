import DomainAuthentication
import DomainLearningProject
import DomainMember
import Foundation

struct NoopFetchLearningProjectsUseCase: FetchLearningProjectsUseCase {
    func callAsFunction(page _: Int) async throws -> LearningProjectPage {
        throw CancellationError()
    }
}
