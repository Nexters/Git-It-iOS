import DomainAuthentication
import DomainLearningProject
import DomainMember
import Foundation

struct NoopUpdateMemberPositionUseCase: UpdateMemberPositionUseCase {
    func callAsFunction(_: MemberPosition) async throws {
        throw CancellationError()
    }
}
