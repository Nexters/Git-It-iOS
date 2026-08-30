import ComposableArchitecture
import DomainAuthentication
import DomainMember
import Foundation

struct AppEntryPreviewFetchMemberProfile: FetchMemberProfileUseCase {
    func callAsFunction() async throws -> MemberProfile {
        MemberProfile(
            name: "미리보기",
            email: "preview@example.com",
            position: nil,
            careerLevel: nil,
            statistics: LearningStatistics(totalAnsweredCount: 0, totalCorrectCount: 0, weeklyCounts: []),
        )
    }
}
