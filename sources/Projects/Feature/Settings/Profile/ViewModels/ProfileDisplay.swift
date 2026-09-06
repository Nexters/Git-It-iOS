import DomainMember
import Foundation

struct ProfileDisplay: Equatable, Sendable {

    // MARK: Lifecycle

    init(
        _ profileLoad: ProfileFeature.State.ProfileLoad,
        todayLabel: String = Self.currentDayLabel(),
    ) {
        let profile: MemberProfile? =
            switch profileLoad {
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

        var id: String {
            dayLabel
        }
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
        let source = counts.isEmpty
            ? defaultDayLabels.map { WeeklyLearningCount(dayLabel: $0, count: 0) }
            : counts
        return source.map {
            WeeklyBar(dayLabel: $0.dayLabel, count: $0.count, isHighlighted: $0.dayLabel == todayLabel)
        }
    }

}
