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
    public let position: String?
    public let careerLevel: String?
    public let thisWeekSolvedCount: Int
    public let thisMonthSolvedCount: Int
    public let streakDays: Int
    public let weeklyChart: [WeeklyChartItemDTO]

}
