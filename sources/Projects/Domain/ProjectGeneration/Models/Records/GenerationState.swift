import DomainIdentifier
import Foundation

public struct GenerationState: Equatable, Sendable {

    // MARK: Lifecycle

    public init(records: [GenerationRecord] = []) {
        self.records = records
    }

    // MARK: Public

    public let records: [GenerationRecord]

    public var activeProjectIDs: Set<ProjectID> {
        Set(records.filter { $0.status == .inProgress }.compactMap(\.projectID))
    }

    public func isCreating(repositoryURL: ExternalRepositoryURL) -> Bool {
        let key = GenerationRecord.normalizedURL(repositoryURL)
        return records.contains { $0.repositoryURL == key && $0.status == .inProgress }
    }

    public func record(projectID: ProjectID) -> GenerationRecord? {
        records.first { $0.projectID == projectID }
    }

    public func record(repositoryURL: ExternalRepositoryURL) -> GenerationRecord? {
        let key = GenerationRecord.normalizedURL(repositoryURL)
        return records.first { $0.repositoryURL == key }
    }

    public func beginning(
        repositoryURL: ExternalRepositoryURL,
        requestedAt: Date,
    ) -> GenerationState? {
        guard !isCreating(repositoryURL: repositoryURL) else { return nil }
        let key = GenerationRecord.normalizedURL(repositoryURL)
        let remaining = records.filter { $0.repositoryURL != key }
        return GenerationState(
            records: remaining + [GenerationRecord(
                repositoryURL: key,
                requestedAt: requestedAt,
            )]
        )
    }

    public func attachingProjectID(
        _ projectID: ProjectID,
        toRepositoryURL repositoryURL: ExternalRepositoryURL,
    ) -> GenerationState {
        let key = GenerationRecord.normalizedURL(repositoryURL)
        let cleared = records.filter { $0.projectID != projectID || $0.repositoryURL == key }
        return GenerationState(
            records: cleared.map { record in
                record.repositoryURL == key ? record.attachingProjectID(projectID) : record
            }
        )
    }

    public func finishing(
        projectID: ProjectID,
        status: GenerationRecord.Status,
        at finishedAt: Date,
    ) -> GenerationState {
        GenerationState(
            records: records.map { record in
                record.projectID == projectID
                    ? record.finishing(
                        status: status,
                        at: finishedAt,
                    )
                    : record
            }
        )
    }

    public func removing(repositoryURL: ExternalRepositoryURL) -> GenerationState {
        let key = GenerationRecord.normalizedURL(repositoryURL)
        return GenerationState(records: records.filter { $0.repositoryURL != key })
    }

    public func removing(projectID: ProjectID) -> GenerationState {
        GenerationState(records: records.filter { $0.projectID != projectID })
    }

    public func purgingExpired(
        now: Date,
        retentionLimit: TimeInterval,
    ) -> GenerationState {
        GenerationState(
            records: records.filter { !$0.isExpired(
                now: now,
                retentionLimit: retentionLimit,
            ) }
        )
    }

}
