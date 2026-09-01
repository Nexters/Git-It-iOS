import Foundation

public struct GenerationProgressDTO: Codable, Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        projectID: String,
        requestedAt: Date,
    ) {
        self.projectID = projectID
        self.requestedAt = requestedAt
    }

    // MARK: Public

    public let projectID: String
    public let requestedAt: Date

}
