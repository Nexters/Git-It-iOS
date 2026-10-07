import Foundation

public struct GenerationState: Equatable, Sendable {

    // MARK: Lifecycle

    public init(records: [GenerationRecord] = []) {
        self.records = records
    }

    // MARK: Public

    public let records: [GenerationRecord]

    public var activeProjectIDs: Set<String> {
        Set(records.filter { $0.status == .inProgress }.compactMap(\.projectID))
    }

    public func isCreating(githubRepoURL: String) -> Bool {
        let key = GenerationRecord.normalizedURL(githubRepoURL)
        return records.contains { $0.githubRepoURL == key && $0.status == .inProgress }
    }

    public func record(projectID: String) -> GenerationRecord? {
        records.first { $0.projectID == projectID }
    }

    public func record(githubRepoURL: String) -> GenerationRecord? {
        let key = GenerationRecord.normalizedURL(githubRepoURL)
        return records.first { $0.githubRepoURL == key }
    }

    public func beginning(
        githubRepoURL: String,
        requestedAt: Date,
    ) -> GenerationState? {
        guard !isCreating(githubRepoURL: githubRepoURL) else { return nil }
        let key = GenerationRecord.normalizedURL(githubRepoURL)
        let remaining = records.filter { $0.githubRepoURL != key }
        return GenerationState(
            records: remaining + [GenerationRecord(githubRepoURL: key, requestedAt: requestedAt)]
        )
    }

    public func attachingProjectID(
        _ projectID: String,
        toGithubRepoURL githubRepoURL: String,
    ) -> GenerationState {
        let key = GenerationRecord.normalizedURL(githubRepoURL)
        let cleared = records.filter { $0.projectID != projectID || $0.githubRepoURL == key }
        return GenerationState(
            records: cleared.map { record in
                record.githubRepoURL == key ? record.attachingProjectID(projectID) : record
            }
        )
    }

    public func finishing(
        projectID: String,
        status: GenerationRecord.Status,
        at finishedAt: Date,
    ) -> GenerationState {
        GenerationState(
            records: records.map { record in
                record.projectID == projectID
                    ? record.finishing(status: status, at: finishedAt)
                    : record
            }
        )
    }

    public func removing(githubRepoURL: String) -> GenerationState {
        let key = GenerationRecord.normalizedURL(githubRepoURL)
        return GenerationState(records: records.filter { $0.githubRepoURL != key })
    }

    public func removing(projectID: String) -> GenerationState {
        GenerationState(records: records.filter { $0.projectID != projectID })
    }

    public func purgingExpired(
        now: Date,
        retentionLimit: TimeInterval,
    ) -> GenerationState {
        GenerationState(
            records: records.filter { !$0.isExpired(now: now, retentionLimit: retentionLimit) }
        )
    }

}
