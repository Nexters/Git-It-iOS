public struct LearningProjectPage: Sendable, Equatable {
    public init(
        projects: [LearningProjectSummary],
        hasNextPage: Bool,
    ) {
        self.projects = projects
        self.hasNextPage = hasNextPage
    }

    public let projects: [LearningProjectSummary]
    public let hasNextPage: Bool
}
