import Foundation

public struct LegacyRepositoryCreationStateDTO: Codable, Equatable, Sendable {

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
    public let projectID: String?
    public let recordedAt: Date

}
