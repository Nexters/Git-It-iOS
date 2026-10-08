import Foundation

// MARK: - PushMessagingClient

public protocol PushMessagingClient: Sendable {
    func registrationToken() async throws -> String
    func setAPNsToken(_ token: Data)

    func registrationTokenRefreshes() -> AsyncStream<String>
}
