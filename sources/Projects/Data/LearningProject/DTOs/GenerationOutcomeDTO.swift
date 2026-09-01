public struct GenerationOutcomeDTO: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        projectID: String,
        status: RawStatus,
    ) {
        self.projectID = projectID
        self.status = status
    }

    public init?(rawPayload: [String: String]) {
        guard
            let projectID = rawPayload["projectId"],
            let statusValue = rawPayload["status"],
            let status = RawStatus(rawValue: statusValue)
        else { return nil }
        self.init(projectID: projectID, status: status)
    }

    // MARK: Public

    public enum RawStatus: String, Sendable {
        case completed
        case failed
    }

    public let projectID: String
    public let status: RawStatus

}
