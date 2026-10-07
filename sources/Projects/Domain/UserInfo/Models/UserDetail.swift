public struct UserDetail: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        name: String,
        email: String,
        statistics: LearningStatistics,
    ) {
        self.name = name
        self.email = email
        self.statistics = statistics
    }

    // MARK: Public

    public let name: String
    public let email: String
    public let statistics: LearningStatistics

}
