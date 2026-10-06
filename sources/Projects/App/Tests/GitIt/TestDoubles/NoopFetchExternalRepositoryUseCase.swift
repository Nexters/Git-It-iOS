import DomainLearningProject
import Foundation

struct NoopFetchExternalRepositoryUseCase: FetchExternalRepositoryUseCase {
    func callAsFunction(url _: String) async throws -> ExternalRepository {
        throw CancellationError()
    }
}
