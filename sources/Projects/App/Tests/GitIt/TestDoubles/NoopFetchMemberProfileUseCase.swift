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
            statistics: LearningStatistics(thisWeekSolvedCount: 0, thisMonthSolvedCount: 0, streakDays: 0, weeklyCounts: []),
        )
    }
}
