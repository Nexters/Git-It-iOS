import DomainMember
import Foundation

/// `ProfileFeature.State.ProfileLoad`를 프로필 화면(Figma `1539:19209`)의 표시 값으로 변환한다.
struct ProfileDisplay: Equatable, Sendable {

    // MARK: Lifecycle

    init(
        _ profileLoad: ProfileFeature.State.ProfileLoad,
        todayLabel: String = Self.currentDayLabel(),
    ) {
        // 받은 값이 있을 때만 채우고, 대기·로딩·실패는 모두 같은 빈 표시 값을 쓴다.
        let profile: MemberProfile? = switch profileLoad {
        case .loaded(let loaded):
            loaded

        case .idle,
             .loading,
             .failed:
            nil
        }
        let statistics = profile?.statistics

        name = profile?.name
        email = profile?.email
        positionBadgeText = profile.flatMap(\.position).map(PositionDisplay.title(for:))
        careerLevelBadgeText = profile.flatMap(\.careerLevel).map(CareerLevelDisplay.title(for:))
        thisWeekSolvedCount = statistics?.thisWeekSolvedCount ?? 0
        thisMonthSolvedCount = statistics?.thisMonthSolvedCount ?? 0
        streakDays = statistics?.streakDays ?? 0
        weeklyBars = Self.weeklyBars(from: statistics?.weeklyCounts ?? [], todayLabel: todayLabel)

        switch profileLoad {
        case .loaded:
            isLoading = false
            isFailed = false

        case .idle,
             .loading:
            isLoading = true
            isFailed = false

        case .failed:
            isLoading = false
            isFailed = true
        }
    }

    // MARK: Internal

    struct WeeklyBar: Equatable, Sendable, Identifiable {
        let dayLabel: String
        let count: Int
        let isHighlighted: Bool

        var id: String { dayLabel }
    }

    static let defaultDayLabels = ["월", "화", "수", "목", "금", "토", "일"]

    let name: String?
    let email: String?
    let positionBadgeText: String?
    let careerLevelBadgeText: String?
    let thisWeekSolvedCount: Int
    let thisMonthSolvedCount: Int
    let streakDays: Int
    let weeklyBars: [WeeklyBar]
    let isLoading: Bool
    let isFailed: Bool

    var hasBadges: Bool {
        positionBadgeText != nil || careerLevelBadgeText != nil
    }

    /// 이번 주 풀이가 없으면 Figma 문구를, 있으면 풀이 수를 담은 문구를 보여 준다.
    var weeklyTitle: String {
        thisWeekSolvedCount == 0
            ? "이번 주 첫 문제를 풀어볼까요?"
            : "이번 주 \(thisWeekSolvedCount)문제를 풀었어요"
    }

    var maxWeeklyCount: Int {
        weeklyBars.map(\.count).max() ?? 0
    }

    static func currentDayLabel(
        date: Date = Date(),
        calendar: Calendar = .current,
    ) -> String {
        // 서버 `dayLabel`("월"…"일")과 같은 한 글자 한국어 요일로 오늘을 표시한다.
        var koreanCalendar = calendar
        koreanCalendar.locale = Locale(identifier: "ko_KR")
        let weekdayIndex = koreanCalendar.component(.weekday, from: date) - 1
        let symbols = koreanCalendar.veryShortWeekdaySymbols
        guard symbols.indices.contains(weekdayIndex) else { return "" }
        return symbols[weekdayIndex]
    }

    // MARK: Private

    private static func weeklyBars(
        from counts: [WeeklyLearningCount],
        todayLabel: String,
    ) -> [WeeklyBar] {
        // 서버가 주간 데이터를 주지 않으면 요일 축만 있는 빈 그래프를 유지한다.
        let source = counts.isEmpty
            ? defaultDayLabels.map { WeeklyLearningCount(dayLabel: $0, count: 0) }
            : counts
        return source.map {
            WeeklyBar(dayLabel: $0.dayLabel, count: $0.count, isHighlighted: $0.dayLabel == todayLabel)
        }
    }

}
