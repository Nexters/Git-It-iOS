import DomainUserInfo
import Testing

@testable import Feature

@Suite("ProfileDisplay")
struct ProfileDisplayTests {

    // MARK: Internal

    @Test
    func `로딩 성공은 이름·이메일·통계 3종을 그대로 노출한다`() {
        let display = ProfileDisplay(.loaded(profile(position: .backend, careerLevel: .entry)), todayLabel: "수")

        #expect(display.name == "프로덕션에 푸시하는 고양이")
        #expect(display.email == "kimlee@github.io")
        #expect(display.thisWeekSolvedCount == 11)
        #expect(display.thisMonthSolvedCount == 27)
        #expect(display.streakDays == 4)
        #expect(!display.isLoading)
        #expect(!display.isFailed)
    }

    @Test
    func `직군·연차 배지는 큐레이션이 있을 때만 만들고 없으면 숨긴다`() {
        let curated = ProfileDisplay(.loaded(profile(position: .backend, careerLevel: .entry)), todayLabel: "수")
        #expect(curated.positionBadgeText == "Back-end")
        #expect(curated.careerLevelBadgeText == "입문")
        #expect(curated.hasBadges)

        let uncurated = ProfileDisplay(.loaded(profile(position: nil, careerLevel: nil)), todayLabel: "수")
        #expect(uncurated.positionBadgeText == nil)
        #expect(uncurated.careerLevelBadgeText == nil)
        #expect(!uncurated.hasBadges)
    }

    @Test
    func `연차 배지 문구는 입문·주니어·미들·시니어다`() {
        #expect(ProfileDisplay(.loaded(profile(careerLevel: .entry)), todayLabel: "").careerLevelBadgeText == "입문")
        #expect(ProfileDisplay(.loaded(profile(careerLevel: .junior)), todayLabel: "").careerLevelBadgeText == "주니어")
        #expect(ProfileDisplay(.loaded(profile(careerLevel: .middle)), todayLabel: "").careerLevelBadgeText == "미들")
        #expect(ProfileDisplay(.loaded(profile(careerLevel: .senior)), todayLabel: "").careerLevelBadgeText == "시니어")
    }

    @Test
    func `주간 추이는 서버 요일 라벨과 개수를 순서대로 보존하고 오늘만 강조한다`() {
        let display = ProfileDisplay(.loaded(profile(position: .backend, careerLevel: .entry)), todayLabel: "수")

        #expect(display.weeklyBars.map(\.dayLabel) == ["월", "화", "수", "목", "금", "토", "일"])
        #expect(display.weeklyBars.map(\.count) == [3, 0, 5, 2, 0, 1, 0])
        #expect(display.weeklyBars.map(\.isHighlighted) == [false, false, true, false, false, false, false])
        #expect(display.maxWeeklyCount == 5)
    }

    @Test
    func `주간 데이터가 비어 있으면 7개 요일 축을 0으로 채운다`() {
        let empty = profile(position: nil, careerLevel: nil, statistics: emptyStatistics)
        let display = ProfileDisplay(.loaded(empty), todayLabel: "월")

        #expect(display.weeklyBars.map(\.dayLabel) == ProfileDisplay.defaultDayLabels)
        #expect(display.weeklyBars.map(\.count).allSatisfy { $0 == 0 })
        #expect(display.weeklyBars.first?.isHighlighted == true)
        #expect(display.maxWeeklyCount == 0)
    }

    @Test
    func `주간 제목은 이번 주 풀이가 없을 때만 첫 문제 안내를 보여 준다`() {
        let empty = profile(position: nil, careerLevel: nil, statistics: emptyStatistics)
        #expect(ProfileDisplay(.loaded(empty), todayLabel: "").weeklyTitle == "이번 주 첫 문제를 풀어볼까요?")

        let active = ProfileDisplay(.loaded(profile(position: .ios, careerLevel: .junior)), todayLabel: "")
        #expect(active.weeklyTitle == "이번 주 11문제를 풀었어요")
    }

    @Test
    func `대기와 로딩은 로딩 표시만 세우고 실패는 실패 표시만 세운다`() {
        let idle = ProfileDisplay(.idle, todayLabel: "")
        #expect(idle.isLoading)
        #expect(!idle.isFailed)
        #expect(idle.name == nil)

        let loading = ProfileDisplay(.loading, todayLabel: "")
        #expect(loading.isLoading)
        #expect(!loading.isFailed)

        let failed = ProfileDisplay(.failed(.temporarilyUnavailable), todayLabel: "")
        #expect(!failed.isLoading)
        #expect(failed.isFailed)
        #expect(failed.name == nil)
        #expect(failed.weeklyBars.count == 7)
    }

    // MARK: Private

    private let emptyStatistics = LearningStatistics(
        thisWeekSolvedCount: 0,
        thisMonthSolvedCount: 0,
        streakDays: 0,
        weeklyCounts: [],
    )

    private var activeStatistics: LearningStatistics {
        LearningStatistics(
            thisWeekSolvedCount: 11,
            thisMonthSolvedCount: 27,
            streakDays: 4,
            weeklyCounts: [
                WeeklyLearningCount(dayLabel: "월", count: 3),
                WeeklyLearningCount(dayLabel: "화", count: 0),
                WeeklyLearningCount(dayLabel: "수", count: 5),
                WeeklyLearningCount(dayLabel: "목", count: 2),
                WeeklyLearningCount(dayLabel: "금", count: 0),
                WeeklyLearningCount(dayLabel: "토", count: 1),
                WeeklyLearningCount(dayLabel: "일", count: 0),
            ],
        )
    }

    private func profile(
        position: MemberPosition? = .backend,
        careerLevel: CareerLevel?,
        statistics: LearningStatistics? = nil,
    ) -> UserProfile {
        let curation: Curation? =
            if let position, let careerLevel {
                Curation(position: position, careerLevel: careerLevel)
            } else {
                nil
            }
        return UserProfile(
            detail: UserDetail(
                name: "프로덕션에 푸시하는 고양이",
                email: "kimlee@github.io",
                statistics: statistics ?? activeStatistics,
            ),
            curation: curation,
        )
    }

}
