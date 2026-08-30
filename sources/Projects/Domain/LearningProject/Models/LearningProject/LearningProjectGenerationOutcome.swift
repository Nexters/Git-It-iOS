public struct LearningProjectGenerationOutcome: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        projectID: String,
        status: Status,
    ) {
        self.projectID = projectID
        self.status = status
    }

    // MARK: Public

    public enum Status: Equatable, Sendable {
        case completed
        case failed
    }

    public let projectID: String
    public let status: Status

}
