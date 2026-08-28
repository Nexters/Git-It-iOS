import DomainAuthentication
import DomainLearningProject
import DomainMember
import Foundation

struct NoopCompleteCurationUseCase: CompleteCurationUseCase {
    func callAsFunction(
        position _: MemberPosition,
        careerLevel _: CareerLevel,
    ) async throws { }
}
