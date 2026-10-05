import DomainUseCaseInterface
import Foundation

struct NoopExternalRepositoryUseCase: ExternalRepositoryUseCase {
    func repository(at _: ExternalRepositoryURL) async throws -> ExternalRepository {
        throw ExternalRepositoryError.other
    }
}
