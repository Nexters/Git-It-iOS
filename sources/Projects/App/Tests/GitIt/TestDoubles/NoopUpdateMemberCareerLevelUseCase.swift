import DomainAuthentication
import DomainLearningProject
import DomainMember
import Foundation

struct NoopUpdateMemberCareerLevelUseCase: UpdateMemberCareerLevelUseCase {
    func callAsFunction(_: CareerLevel) async throws {
        throw CancellationError()
    }
}
