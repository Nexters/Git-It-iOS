import Foundation

public struct RepositoryCreationState: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        normalizedGithubRepoURL: String,
        projectID: String? = nil,
        recordedAt: Date,
    ) {
        self.normalizedGithubRepoURL = normalizedGithubRepoURL
        self.projectID = projectID
        self.recordedAt = recordedAt
    }

    // MARK: Public

    public let normalizedGithubRepoURL: String
    public var projectID: String?
    public let recordedAt: Date

}
