public struct MemberProfile: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        name: String,
        email: String,
        position: MemberPosition,
        careerLevel: CareerLevel,
        statistics: LearningStatistics,
    ) {
        self.name = name
        self.email = email
        self.position = position
        self.careerLevel = careerLevel
        self.statistics = statistics
    }

    // MARK: Public

    public let name: String
    public let email: String
    public let position: MemberPosition
    public let careerLevel: CareerLevel
    public let statistics: LearningStatistics

}
