import Foundation

public struct GenerationRecordDTO: Codable, Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        githubRepoURL: String,
        projectID: String?,
        requestedAt: Date,
        status: String,
        finishedAt: Date?,
    ) {
        self.githubRepoURL = githubRepoURL
        self.projectID = projectID
        self.requestedAt = requestedAt
        self.status = status
        self.finishedAt = finishedAt
    }

    // MARK: Public

    public let githubRepoURL: String
    public let projectID: String?
    public let requestedAt: Date
    public let status: String
    public let finishedAt: Date?

}
