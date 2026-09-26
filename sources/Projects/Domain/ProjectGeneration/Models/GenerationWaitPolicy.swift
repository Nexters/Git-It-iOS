import Foundation

public struct GenerationWaitPolicy: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        retentionLimit: TimeInterval,
        reminderValidity: TimeInterval,
    ) {
        self.retentionLimit = retentionLimit
        self.reminderValidity = reminderValidity
    }

    // MARK: Public

    public static let standard = GenerationWaitPolicy(
        retentionLimit: 3600,
        reminderValidity: 300,
    )

    public let retentionLimit: TimeInterval
    public let reminderValidity: TimeInterval

    public func expiryDate(for record: GenerationRecord) -> Date {
        (record.finishedAt ?? record.requestedAt).addingTimeInterval(retentionLimit)
    }

    public func isReminderValid(
        _ record: GenerationRecord,
        now: Date,
    ) -> Bool {
        guard let finishedAt = record.finishedAt else { return false }
        return now.timeIntervalSince(finishedAt) <= reminderValidity
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
