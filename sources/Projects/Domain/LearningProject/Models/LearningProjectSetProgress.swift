public struct LearningProjectSetProgress: Equatable, Sendable {
    public init(
        setID: String,
        label: String,
        title: String,
        problemCount: Int,
        completedCount: Int,
    ) {
        self.setID = setID
        self.label = label
        self.title = title
        self.problemCount = problemCount
        self.completedCount = completedCount
    }

    public let setID: String
    public let label: String
    public let title: String
    public let problemCount: Int
    public let completedCount: Int
}
