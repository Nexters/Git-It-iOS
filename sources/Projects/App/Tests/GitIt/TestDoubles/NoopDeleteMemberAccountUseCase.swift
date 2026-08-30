import DomainAuthentication
import DomainLearningProject
import DomainMember
import Foundation

struct NoopDeleteMemberAccountUseCase: DeleteMemberAccountUseCase {
    func callAsFunction() async throws {
        throw CancellationError()
    }
}
