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

    public func readyDate(for progress: GenerationProgress) -> Date {
        progress.requestedAt.addingTimeInterval(minimumWait)
    }

    public func isExpired(
        _ progress: GenerationProgress,
        now: Date,
    ) -> Bool {
        now.timeIntervalSince(progress.requestedAt) > retentionLimit
    }

}
