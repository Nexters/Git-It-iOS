import DomainAuthentication
import DomainLearningProject
import DomainMember
import Foundation

struct NoopFetchMemberProfileUseCase: FetchMemberProfileUseCase {
    func callAsFunction() async throws -> MemberProfile {
        MemberProfile(
            name: "테스터",
            email: "tester@example.com",
            position: nil,
            careerLevel: nil,
            statistics: LearningStatistics(totalAnsweredCount: 0, totalCorrectCount: 0, weeklyCounts: []),
        )
    }
}
