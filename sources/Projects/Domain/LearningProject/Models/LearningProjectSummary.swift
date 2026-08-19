public struct LearningProjectSummary: Identifiable, Sendable, Equatable {
    public init(
        id: LearningProjectID,
        name: String,
        technologies: String,
        progress: LearningProgress,
        nextSet: LearningSetMark,
    ) {
        self.id = id
        self.name = name
        self.technologies = technologies
        self.progress = progress
        self.nextSet = nextSet
    }

    public let id: LearningProjectID
    public let name: String
    public let technologies: String
    public let progress: LearningProgress
    public let nextSet: LearningSetMark
}
