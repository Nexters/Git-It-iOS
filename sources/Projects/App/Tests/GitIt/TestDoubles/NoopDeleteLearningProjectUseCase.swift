import DomainAuthentication
import DomainLearningProject
import DomainMember
import Foundation

struct NoopDeleteLearningProjectUseCase: DeleteLearningProjectUseCase {
    func callAsFunction(projectID _: String) async throws {
        throw CancellationError()
    }
}
