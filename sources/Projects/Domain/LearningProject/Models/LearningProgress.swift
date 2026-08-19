public struct LearningProgress: Sendable, Equatable {
    public init(completedRatio: Double) {
        self.completedRatio = completedRatio.isNaN
            ? 0
            : min(max(completedRatio, 0), 1)
    }

    public let completedRatio: Double
}
