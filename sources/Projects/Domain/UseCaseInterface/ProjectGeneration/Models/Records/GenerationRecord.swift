import Foundation

public struct GenerationRecord: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        repositoryURL: ExternalRepositoryURL,
        projectID: ProjectID? = nil,
        requestedAt: Date,
        status: Status = .inProgress,
        finishedAt: Date? = nil,
    ) {
        self.repositoryURL = Self.normalizedURL(repositoryURL)
        self.projectID = projectID
        self.requestedAt = requestedAt
        self.status = status
        self.finishedAt = finishedAt
    }

    // MARK: Public

    public enum Status: Equatable, Sendable {
        case inProgress
        case completed
        case failed
    }

    public let repositoryURL: ExternalRepositoryURL
    public let projectID: ProjectID?
    public let requestedAt: Date
    public let status: Status
    public let finishedAt: Date?

    public static func normalizedURL(_ repositoryURL: ExternalRepositoryURL) -> String {
        var normalized = repositoryURL.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        while normalized.hasSuffix("/") {
            normalized.removeLast()
        }
        return normalized
    }

    public func attachingProjectID(_ projectID: ProjectID) -> GenerationRecord {
        GenerationRecord(
            repositoryURL: repositoryURL,
            projectID: projectID,
            requestedAt: requestedAt,
            status: status,
            finishedAt: finishedAt,
        )
    }

    public func finishing(
        status: Status,
        at finishedAt: Date,
    ) -> GenerationRecord {
        guard self.status == .inProgress, status != .inProgress else { return self }
        return GenerationRecord(
            repositoryURL: repositoryURL,
            projectID: projectID,
            requestedAt: requestedAt,
            status: status,
            finishedAt: finishedAt,
        )
    }

    public func isExpired(
        now: Date,
        retentionLimit: TimeInterval,
    ) -> Bool {
        let reference = finishedAt ?? requestedAt
        return now.timeIntervalSince(reference) > retentionLimit
    }

}
