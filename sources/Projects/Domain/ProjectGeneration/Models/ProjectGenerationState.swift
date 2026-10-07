import DomainIdentifier

public struct ProjectGenerationState: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        requests: [ProjectGenerationRequestState],
        preparingProjectIDs: Set<ProjectID>,
    ) {
        self.requests = requests
        self.preparingProjectIDs = preparingProjectIDs
    }

    // MARK: Public

    public let requests: [ProjectGenerationRequestState]
    public let preparingProjectIDs: Set<ProjectID>

}
