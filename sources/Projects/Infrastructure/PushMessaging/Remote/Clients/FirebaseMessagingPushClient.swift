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

    // MARK: Private

    private struct State {
        var pendingContinuations = [CheckedContinuation<String, Never>]()
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
        let continuations = state.withLock { protectedState -> [CheckedContinuation<String, Never>] in
            defer { protectedState.pendingContinuations.removeAll() }
            return protectedState.pendingContinuations
        }
        for continuation in continuations {
            continuation.resume(returning: fcmToken)
        }
    }
}
