import Foundation

public struct WeeklyLearningCount: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        weekStartDate: Date,
        count: Int,
    ) {
        self.weekStartDate = weekStartDate
        self.count = count
    }

    // MARK: Public

    public let weekStartDate: Date
    public let count: Int

}
