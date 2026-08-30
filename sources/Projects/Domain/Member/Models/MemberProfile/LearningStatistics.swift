public struct LearningStatistics: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        totalAnsweredCount: Int,
        totalCorrectCount: Int,
        weeklyCounts: [WeeklyLearningCount],
    ) {
        self.totalAnsweredCount = totalAnsweredCount
        self.totalCorrectCount = totalCorrectCount
        self.weeklyCounts = weeklyCounts
    }

    // MARK: Public

    public let totalAnsweredCount: Int
    public let totalCorrectCount: Int
    public let weeklyCounts: [WeeklyLearningCount]

}
