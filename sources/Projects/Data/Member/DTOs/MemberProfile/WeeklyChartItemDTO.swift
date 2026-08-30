public struct WeeklyChartItemDTO: Decodable, Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        date: String,
        solvedCount: Int,
    ) {
        self.init(dayLabel: date, count: solvedCount)
    }

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

    public var date: String {
        dayLabel
    }

    public var solvedCount: Int {
        count
    }

}
