import Foundation

// MARK: - NotificationAppCallbacks

public struct NotificationAppCallbacks: Sendable {

    // MARK: Lifecycle

    public init(
        forwardDeviceToken: @escaping @Sendable (Data) -> Void,
        ingestRemoteMessagePayload: @escaping @Sendable ([String: String]) async -> Void,
    ) {
        self.forwardDeviceToken = forwardDeviceToken
        self.ingestRemoteMessagePayload = ingestRemoteMessagePayload
    }

    // MARK: Public

    public let forwardDeviceToken: @Sendable (Data) -> Void
    public let ingestRemoteMessagePayload: @Sendable ([String: String]) async -> Void

}
