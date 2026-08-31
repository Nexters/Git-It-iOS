import Foundation

// MARK: - PushNotificationHandlers

public struct PushNotificationHandlers: Sendable {

    // MARK: Lifecycle

    public init(
        forwardAPNsToken: @escaping @Sendable (Data) -> Void,
        ingestPushPayload: @escaping @Sendable ([String: String]) async -> Void,
    ) {
        self.forwardAPNsToken = forwardAPNsToken
        self.ingestPushPayload = ingestPushPayload
    }

    // MARK: Public

    public let forwardAPNsToken: @Sendable (Data) -> Void
    public let ingestPushPayload: @Sendable ([String: String]) async -> Void

}
