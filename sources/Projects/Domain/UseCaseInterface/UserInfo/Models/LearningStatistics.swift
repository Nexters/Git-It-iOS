public struct LearningStatistics: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        thisWeekSolvedCount: Int,
        thisMonthSolvedCount: Int,
        streakDays: Int,
        weeklyCounts: [WeeklyLearningCount],
    ) {
        self.thisWeekSolvedCount = thisWeekSolvedCount
        self.thisMonthSolvedCount = thisMonthSolvedCount
        self.streakDays = streakDays
        self.weeklyCounts = weeklyCounts
    }

    // MARK: Public

    public let thisWeekSolvedCount: Int
    public let thisMonthSolvedCount: Int
    public let streakDays: Int
    public let weeklyCounts: [WeeklyLearningCount]

}
