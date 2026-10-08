import Foundation

public struct GenerationWaitPolicy: Equatable, Sendable {

    // MARK: Lifecycle

    public init(retentionLimit: TimeInterval) {
        self.retentionLimit = retentionLimit
    }

    // MARK: Public

    public static let standard = GenerationWaitPolicy(retentionLimit: 3600)

    public let retentionLimit: TimeInterval

    public func expiryDate(for record: GenerationRecord) -> Date {
        (record.finishedAt ?? record.requestedAt).addingTimeInterval(retentionLimit)
    }

    public func isExpired(
        _ record: GenerationRecord,
        now: Date,
    ) -> Bool {
        record.isExpired(
            now: now,
            retentionLimit: retentionLimit,
        )
    }

}
