import Foundation

// MARK: - PushMessagingClient

public protocol PushMessagingClient: Sendable {
    func registrationToken() async throws -> String
    func setAPNsToken(_ token: Data)
    /// 최초 발급은 `registrationToken()`이 담당하고, 이 스트림은 이후의 갱신만 방출한다.
    func registrationTokenRefreshes() -> AsyncStream<String>
}
