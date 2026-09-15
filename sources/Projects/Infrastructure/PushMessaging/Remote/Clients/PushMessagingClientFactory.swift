import Foundation

// MARK: - PushMessagingClientFactory

public enum PushMessagingClientFactory {

    // MARK: Public

    public static func make() -> any PushMessagingClient {
        FirebaseMessagingPushClient()
    }

}
