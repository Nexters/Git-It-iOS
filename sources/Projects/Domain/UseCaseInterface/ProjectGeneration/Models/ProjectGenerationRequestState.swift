import Foundation

public struct ProjectGenerationRequestState: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        repositoryURL: ExternalRepositoryURL,
        projectID: ProjectID?,
        requestedAt: Date,
        phase: ProjectGenerationPhase,
    ) {
        self.repositoryURL = repositoryURL
        self.projectID = projectID
        self.requestedAt = requestedAt
        self.phase = phase
    }

    // MARK: Public

    public let repositoryURL: ExternalRepositoryURL
    public let projectID: ProjectID?
    public let requestedAt: Date
    public let phase: ProjectGenerationPhase

}
