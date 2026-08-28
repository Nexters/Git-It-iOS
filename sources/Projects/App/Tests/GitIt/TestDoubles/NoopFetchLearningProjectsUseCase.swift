import DomainAuthentication
import DomainLearningProject
import DomainMember
import Foundation

struct NoopFetchLearningProjectsUseCase: FetchLearningProjectsUseCase {
    func callAsFunction() async throws -> LearningProjectPage {
        throw CancellationError()
    }
}
