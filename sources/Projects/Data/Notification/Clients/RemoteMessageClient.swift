import Foundation
import InfrastructurePushMessaging

// MARK: - RemoteMessageClient

struct RemoteMessageClient: RemoteMessageReceiver {

    // MARK: Lifecycle

    init(pushClient: any PushMessagingClient = PushMessagingClientFactory.make()) {
        self.pushClient = pushClient
    }

    // MARK: Internal

    func registrationToken() async throws -> String {
        try await pushClient.registrationToken()
    }

    func registrationTokenRefreshes() -> AsyncStream<String> {
        pushClient.registrationTokenRefreshes()
    }

    func setDeviceToken(_ token: Data) {
        pushClient.setAPNsToken(token)
    }

    // MARK: Private

    private let pushClient: any PushMessagingClient

}
