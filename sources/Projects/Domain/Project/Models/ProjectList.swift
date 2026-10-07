public struct ProjectList: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        summaries: [ProjectSummary],
        hasNextPage: Bool,
        isLoaded: Bool,
    ) {
        self.summaries = summaries
        self.hasNextPage = hasNextPage
        self.isLoaded = isLoaded
    }

    // MARK: Public

    public let summaries: [ProjectSummary]
    public let hasNextPage: Bool
    public let isLoaded: Bool

}
