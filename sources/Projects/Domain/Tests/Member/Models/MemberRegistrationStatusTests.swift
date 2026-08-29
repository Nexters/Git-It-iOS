import Testing

@testable import DomainMember

@Suite("MemberRegistrationStatus")
struct MemberRegistrationStatusTests {
    @Test
    func `등록 완료 미가입 재시도 오류가 서로 합쳐지지 않는다`() {
        let statistics = LearningStatistics(totalAnsweredCount: 0, totalCorrectCount: 0, weeklyCounts: [])
        let profile = MemberProfile(
            name: "홍길동",
            email: "gildong@example.com",
            position: .ios,
            careerLevel: .entry,
            statistics: statistics,
        )
        let registered = MemberRegistrationStatus.registered(profile: profile)
        let unregistered = MemberRegistrationStatus.unregistered
        let retryableFailure = MemberRegistrationStatus.retryableFailure

        #expect(registered != unregistered)
        #expect(unregistered != retryableFailure)
        #expect(registered != retryableFailure)

        guard case .registered(let registeredProfile) = registered else {
            Issue.record("registered 케이스여야 한다")
            return
        }
        #expect(registeredProfile == profile)
    }
}
