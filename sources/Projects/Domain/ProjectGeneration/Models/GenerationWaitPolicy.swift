import Foundation

public struct GenerationWaitPolicy: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        minimumWait: TimeInterval,
        retentionLimit: TimeInterval,
    ) {
        self.minimumWait = minimumWait
        self.retentionLimit = retentionLimit
    }

    // MARK: Public

    public static let standard = GenerationWaitPolicy(
        minimumWait: 300,
        retentionLimit: 3600,
    )

    public let minimumWait: TimeInterval
    public let retentionLimit: TimeInterval

    public func readyDate(for record: GenerationRecord) -> Date {
        record.requestedAt.addingTimeInterval(minimumWait)
    }

    public func isExpired(
        _ record: GenerationRecord,
        now: Date,
    ) -> Bool {
        record.isExpired(now: now, retentionLimit: retentionLimit)
    }

}
