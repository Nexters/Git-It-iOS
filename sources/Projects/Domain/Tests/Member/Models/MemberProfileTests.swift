import Testing

@testable import DomainMember

@Suite("MemberProfile")
struct MemberProfileTests {
    @Test
    func `position과 careerLevel의 개별 null을 그대로 보존한다`() {
        let statistics = LearningStatistics(thisWeekSolvedCount: 0, thisMonthSolvedCount: 0, streakDays: 0, weeklyCounts: [])
        let bothMissing = MemberProfile(
            name: "홍길동",
            email: "gildong@example.com",
            position: nil,
            careerLevel: nil,
            statistics: statistics,
        )
        let positionOnly = MemberProfile(
            name: "홍길동",
            email: "gildong@example.com",
            position: .ios,
            careerLevel: nil,
            statistics: statistics,
        )
        let careerOnly = MemberProfile(
            name: "홍길동",
            email: "gildong@example.com",
            position: nil,
            careerLevel: .senior,
            statistics: statistics,
        )

        #expect(bothMissing.position == nil)
        #expect(bothMissing.careerLevel == nil)
        #expect(positionOnly.position == .ios)
        #expect(positionOnly.careerLevel == nil)
        #expect(careerOnly.position == nil)
        #expect(careerOnly.careerLevel == .senior)
    }

    @Test
    func `둘 중 하나가 null이면 전체 큐레이션이 필요하다`() {
        let statistics = LearningStatistics(thisWeekSolvedCount: 0, thisMonthSolvedCount: 0, streakDays: 0, weeklyCounts: [])
        let profiles = [
            MemberProfile(name: "A", email: "a@example.com", position: nil, careerLevel: .entry, statistics: statistics),
            MemberProfile(name: "B", email: "b@example.com", position: .ios, careerLevel: nil, statistics: statistics),
            MemberProfile(name: "C", email: "c@example.com", position: nil, careerLevel: nil, statistics: statistics),
        ]
        let complete = MemberProfile(
            name: "D",
            email: "d@example.com",
            position: .ios,
            careerLevel: .entry,
            statistics: statistics,
        )

        for profile in profiles {
            #expect(profile.position == nil || profile.careerLevel == nil)
        }
        #expect(complete.position != nil && complete.careerLevel != nil)
    }
}
