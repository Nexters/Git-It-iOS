import Foundation

public struct GenerationRecord: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        githubRepoURL: String,
        projectID: String? = nil,
        requestedAt: Date,
        status: Status = .inProgress,
        finishedAt: Date? = nil,
    ) {
        self.githubRepoURL = Self.normalizedURL(githubRepoURL)
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

    public let githubRepoURL: String
    public let projectID: String?
    public let requestedAt: Date
    public let status: Status
    public let finishedAt: Date?

    public static func normalizedURL(_ githubRepoURL: String) -> String {
        var normalized = githubRepoURL.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        while normalized.hasSuffix("/") {
            normalized.removeLast()
        }
        return normalized
    }

    public func attachingProjectID(_ projectID: String) -> GenerationRecord {
        GenerationRecord(
            githubRepoURL: githubRepoURL,
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
            githubRepoURL: githubRepoURL,
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
