/// 서버가 계산한 통계를 그대로 보존한다. 클라이언트는 재계산하지 않는다.
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
    /// 서버 응답 배열 순서를 그대로 보존한다.
    public let weeklyCounts: [WeeklyLearningCount]

}
