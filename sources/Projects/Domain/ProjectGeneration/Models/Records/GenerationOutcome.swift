import DomainIdentifier

public struct GenerationOutcome: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        projectID: ProjectID,
        status: Status,
    ) {
        self.projectID = projectID
        self.status = status
    }

    // MARK: Public

    public enum Status: CaseIterable, Equatable, Sendable {
        case completed
        case failed
    }

    public let projectID: ProjectID
    public let status: Status

}
