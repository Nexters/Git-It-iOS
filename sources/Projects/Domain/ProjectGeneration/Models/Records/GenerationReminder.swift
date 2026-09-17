import DomainIdentifier

public struct GenerationReminder: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        projectID: ProjectID,
        kind: Kind,
    ) {
        self.projectID = projectID
        self.kind = kind
    }

    // MARK: Public

    public enum Kind: CaseIterable, Equatable, Sendable {
        case completed
        case failed
    }

    public let projectID: ProjectID
    public let kind: Kind

}
