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
            !projectID.isEmpty,
            let status = Self.status(in: rawPayload)
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

    // MARK: Private

    private static let statusByType: [String: RawStatus] = [
        "QUIZ_READY": .completed,
        "QUIZ_REJECTED": .failed,
    ]

    private static func status(in rawPayload: [String: String]) -> RawStatus? {
        if let type = rawPayload["type"], let status = statusByType[type] {
            return status
        }
        return rawPayload["status"].flatMap(RawStatus.init(rawValue:))
    }

}
