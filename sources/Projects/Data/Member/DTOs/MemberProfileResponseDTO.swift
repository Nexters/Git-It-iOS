// MARK: - MemberProfileResponseDTO

public struct MemberProfileResponseDTO: Decodable, Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        name: String,
        email: String,
        position: String?,
        careerLevel: String?,
        thisWeekSolvedCount: Int,
        thisMonthSolvedCount: Int,
        streakDays: Int,
        weeklyChart: [WeeklyChartItemDTO],
    ) {
        self.name = name
        self.email = email
        self.position = position
        self.careerLevel = careerLevel
        self.thisWeekSolvedCount = thisWeekSolvedCount
        self.thisMonthSolvedCount = thisMonthSolvedCount
        self.streakDays = streakDays
        self.weeklyChart = weeklyChart
    }

    // MARK: Public

    public let name: String
    public let email: String
    /// 서버 null을 그대로 보존한다. 지원하지 않는 raw value를 nil로 치환하지 않는다.
    public let position: String?
    /// 서버 null을 그대로 보존한다. 지원하지 않는 raw value를 nil로 치환하지 않는다.
    public let careerLevel: String?
    public let thisWeekSolvedCount: Int
    public let thisMonthSolvedCount: Int
    public let streakDays: Int
    public let weeklyChart: [WeeklyChartItemDTO]

}

// MARK: - WeeklyChartItemDTO

public struct WeeklyChartItemDTO: Decodable, Equatable, Sendable {
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

    public let dayLabel: String
    public let count: Int

    public var date: String { dayLabel }
    public var solvedCount: Int { count }
}
