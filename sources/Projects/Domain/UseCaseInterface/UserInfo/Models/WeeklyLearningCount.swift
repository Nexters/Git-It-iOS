public struct WeeklyLearningCount: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        dayLabel: String,
        count: Int,
    ) {
        self.dayLabel = dayLabel
        self.count = count
    }

    // MARK: Public

    public let dayLabel: String
    public let count: Int

}
