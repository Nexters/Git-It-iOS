public struct ProjectPage: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        summaries: [ProjectSummary],
        hasNextPage: Bool,
    ) {
        self.summaries = summaries
        self.hasNextPage = hasNextPage
    }

    // MARK: Public

    public let summaries: [ProjectSummary]
    public let hasNextPage: Bool

}
