import Testing

@testable import DomainMember

// MARK: - FetchMemberProfileTests

@Suite("FetchMemberProfile")
struct FetchMemberProfileTests {
    @Test
    func `전체 프로필과 통계를 손실 없이 전달한다`() async throws {
        let statistics = LearningStatistics(
            thisWeekSolvedCount: 10,
            thisMonthSolvedCount: 7,
            streakDays: 2,
            weeklyCounts: [WeeklyLearningCount(dayLabel: "월", count: 3)],
        )
        let profile = MemberProfile(
            name: "홍길동",
            email: "gildong@example.com",
            position: .ios,
            careerLevel: .senior,
            statistics: statistics,
        )
        let fetchMemberProfile = FetchMemberProfile(repository: FetchMemberProfileRepository(profile: profile))

        let result = try await fetchMemberProfile()

        #expect(result == profile)
        #expect(result.statistics.weeklyCounts.count == 1)
    }

    @Test
    func `member unavailable 오류를 그대로 전파한다`() async throws {
        let fetchMemberProfile = FetchMemberProfile(
            repository: FetchMemberProfileRepository(profile: nil)
        )

        await #expect(throws: MemberError.memberUnavailable) {
            try await fetchMemberProfile()
        }
    }
}

// MARK: - FetchMemberProfileRepository

private struct FetchMemberProfileRepository: MemberRepository {
    let profile: MemberProfile?

    func completeCuration(
        position _: MemberPosition,
        careerLevel _: CareerLevel,
    ) async throws { }

    func fetchProfile() async throws -> MemberProfile {
        guard let profile else { throw MemberError.memberUnavailable }
        return profile
    }

    func updatePosition(_: MemberPosition) async throws { }
    func updateCareerLevel(_: CareerLevel) async throws { }
    func registerDevice(_: MemberDeviceInfo) async throws { }
    func deleteAccount() async throws { }
}
