import Foundation

public struct QuizGenerationOutcomeDTO: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        projectID: String,
        status: RawStatus,
        deliveredAt: Date,
    ) {
        self.projectID = projectID
        self.status = status
        self.deliveredAt = deliveredAt
    }

    public init?(
        rawPayload: [String: String],
        deliveredAt: Date,
    ) {
        guard
            let projectID = rawPayload["projectId"],
            let statusValue = rawPayload["status"],
            let status = RawStatus(rawValue: statusValue)
        else { return nil }
        self.init(
            projectID: projectID,
            status: status,
            deliveredAt: deliveredAt,
        )
    }

    // MARK: Public

    public enum RawStatus: String, Sendable {
        case completed
        case failed
    }

    public let projectID: String
    public let status: RawStatus
    public let deliveredAt: Date

}
