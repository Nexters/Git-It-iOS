import Foundation

public struct GenerationOutcome: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        projectID: ProjectID,
        status: Status,
        arrivedAt: Date,
    ) {
        self.projectID = projectID
        self.status = status
        self.arrivedAt = arrivedAt
    }

    // MARK: Public

    public enum Status: CaseIterable, Equatable, Sendable {
        case completed
        case failed
    }

    public let projectID: ProjectID
    public let status: Status
    public let arrivedAt: Date

}
