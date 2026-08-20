public struct LearningProjectSetProgress: Equatable, Sendable {
    public init(
        setId: String,
        label: String,
        title: String,
        problemCount: Int,
        completedCount: Int,
    ) {
        self.setId = setId
        self.label = label
        self.title = title
        self.problemCount = problemCount
        self.completedCount = completedCount
    }

    public let setId: String
    public let label: String
    public let title: String
    public let problemCount: Int
    public let completedCount: Int
}
