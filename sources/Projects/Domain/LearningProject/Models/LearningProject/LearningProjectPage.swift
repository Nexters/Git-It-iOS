public struct LearningProjectPage: Equatable, Sendable {
    public init(
        items: [LearningProjectSummary],
        hasNext: Bool,
    ) {
        self.items = items
        self.hasNext = hasNext
    }

    public static let firstIndex = 0

    public let items: [LearningProjectSummary]
    public let hasNext: Bool
}
