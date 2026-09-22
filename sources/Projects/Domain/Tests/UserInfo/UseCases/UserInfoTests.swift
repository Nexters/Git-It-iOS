import Foundation
import Testing

@testable import DomainUserInfo

@Suite("UserInfo")
struct UserInfoTests {

    // MARK: Internal

    @Test
    func `동시에 상세와 큐레이션을 조회하면 프로필 요청을 한 번만 보낸다`() async throws {
        let repository = StubUserInfoRepository(
            profile: Self.profile(curation: Self.curation),
            holdsProfile: true,
        )
        let userInfo = UserInfo(repository: repository)

        async let detail = userInfo.detail()
        async let curation = userInfo.curation()
        await Self.settle { await repository.profileCallCount == 1 }
        for _ in 0 ..< 50 {
            await Task.yield()
        }
        await repository.releaseProfile()

        #expect(try await detail == Self.detail)
        #expect(try await curation == Self.curation)
        #expect(await repository.profileCallCount == 1)
    }

    @Test
    func `포지션과 경력 중 하나라도 없으면 큐레이션은 nil이다`() async throws {
        let userInfo = UserInfo(repository: StubUserInfoRepository(profile: Self.profile(curation: nil)))

        #expect(try await userInfo.curation() == nil)
    }

    @Test
    func `조회가 끝난 뒤 다시 조회하면 새로 요청한다`() async throws {
        let repository = StubUserInfoRepository(profile: Self.profile(curation: nil))
        let userInfo = UserInfo(repository: repository)

        _ = try await userInfo.detail()
        _ = try await userInfo.detail()

        #expect(await repository.profileCallCount == 2)
    }

    @Test
    func `변경 요청은 호출 순서대로 하나씩 처리한다`() async throws {
        let repository = StubUserInfoRepository(
            profile: Self.profile(curation: nil),
            holdsFirstUpdate: true,
        )
        let userInfo = UserInfo(repository: repository)

        let position = Task { try await userInfo.updatePosition(.ios) }
        await Self.settle { await repository.events == ["position:start"] }
        let careerLevel = Task { try await userInfo.updateCareerLevel(.senior) }
        for _ in 0 ..< 50 {
            await Task.yield()
        }
        #expect(await repository.events == ["position:start"])

        await repository.releaseUpdate()
        try await position.value
        try await careerLevel.value

        #expect(await repository.events == [
            "position:start",
            "position:end",
            "careerLevel:start",
            "careerLevel:end",
        ])
    }

    // MARK: Private

    private static let detail = UserDetail(
        name: "Git It",
        email: "gitit@example.com",
        statistics: LearningStatistics(
            thisWeekSolvedCount: 3,
            thisMonthSolvedCount: 10,
            streakDays: 2,
            weeklyCounts: [WeeklyLearningCount(
                dayLabel: "월",
                count: 1,
            )],
        ),
    )

    private static let curation = Curation(
        position: .ios,
        careerLevel: .junior,
    )

    private static func profile(curation: Curation?) -> UserProfile {
        UserProfile(
            detail: detail,
            curation: curation,
        )
    }

    private static func settle(until condition: @Sendable () async -> Bool) async {
        for _ in 0 ..< 200 {
            guard await !condition() else { return }
            await Task.yield()
        }
    }

}
