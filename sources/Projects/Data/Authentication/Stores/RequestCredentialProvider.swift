import DataShared
import Foundation
import Synchronization

// MARK: - RequestCredentialProvider

public final class RequestCredentialProvider: Sendable {

    // MARK: Lifecycle

    public init(
        secureStorage: any SecureValueStorage,
        now: @escaping @Sendable () -> Date = { Date() },
    ) {
        coding = SessionRecordStorageCoding(storage: secureStorage)
        self.now = now
    }

    // MARK: Public

    public func credential() async -> RequestCredential {
        guard let record = storedRecord() else { return .signedOut }
        if let expiresAt = record.accessTokenExpiresAt, expiresAt <= now() {
            invalidate()
            return .signedOut
        }
        return .available(record.accessToken)
    }

    public func credentialRejected() async {
        guard storedRecord() != nil else { return }
        invalidate()
    }

    public func invalidations() -> AsyncStream<Void> {
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        let subscriberID = UUID()
        subscribers.withLock { $0[subscriberID] = continuation }
        continuation.onTermination = { [weak self] _ in
            self?.subscribers.withLock { _ = $0.removeValue(forKey: subscriberID) }
        }
        return stream
    }

    // MARK: Private

    private let coding: SessionRecordStorageCoding
    private let now: @Sendable () -> Date
    private let subscribers = Mutex([UUID: AsyncStream<Void>.Continuation]())

    private func storedRecord() -> StoredSessionRecord? {
        guard let record = try? coding.load() else { return nil }
        return record
    }

    private func invalidate() {
        try? coding.delete()
        let continuations = subscribers.withLock { Array($0.values) }
        for continuation in continuations {
            continuation.yield(())
        }
    }

}
