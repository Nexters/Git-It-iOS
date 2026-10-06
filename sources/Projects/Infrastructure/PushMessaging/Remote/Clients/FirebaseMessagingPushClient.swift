import FirebaseCore
import FirebaseMessaging
import Foundation
import Synchronization

// MARK: - FirebaseMessagingPushClient

public final class FirebaseMessagingPushClient: NSObject, PushMessagingClient, Sendable {

    // MARK: Lifecycle

    override public init() {
        super.init()
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        Messaging.messaging().delegate = self
    }

    // MARK: Public

    public func registrationToken() async throws -> String {
        if let token = Messaging.messaging().fcmToken {
            return token
        }
        return await withCheckedContinuation { continuation in
            state.withLock { $0.pendingContinuations.append(continuation) }
        }
    }

    public func setAPNsToken(_ token: Data) {
        Messaging.messaging().apnsToken = token
    }

    public func registrationTokenRefreshes() -> AsyncStream<String> {
        AsyncStream { continuation in
            let subscriptionID = UUID()
            state.withLock { $0.refreshContinuations[subscriptionID] = continuation }
            continuation.onTermination = { [weak self] _ in
                self?.state.withLock { $0.refreshContinuations[subscriptionID] = nil }
            }
        }
    }

    // MARK: Private

    private struct State {
        var pendingContinuations = [CheckedContinuation<String, Never>]()
        var refreshContinuations = [UUID: AsyncStream<String>.Continuation]()
        var hasIssuedInitialToken = false
    }

    private let state = Mutex(State())

}

// MARK: MessagingDelegate

extension FirebaseMessagingPushClient: MessagingDelegate {
    public func messaging(
        _: Messaging,
        didReceiveRegistrationToken fcmToken: String?,
    ) {
        guard let fcmToken else { return }

        let delivery = state.withLock { state -> (
            pending: [CheckedContinuation<String, Never>],
            refreshes: [AsyncStream<String>.Continuation],
        ) in
            let pending = state.pendingContinuations
            state.pendingContinuations.removeAll()

            // 최초 발급은 registrationToken()이 소유하므로 갱신 스트림으로 방출하지 않는다.
            let isRefresh = state.hasIssuedInitialToken
            state.hasIssuedInitialToken = true
            let refreshes = isRefresh ? Array(state.refreshContinuations.values) : []

            return (pending, refreshes)
        }

        for continuation in delivery.pending {
            continuation.resume(returning: fcmToken)
        }
        for continuation in delivery.refreshes {
            continuation.yield(fcmToken)
        }
    }
}
