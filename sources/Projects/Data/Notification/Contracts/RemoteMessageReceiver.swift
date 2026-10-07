import Foundation

// MARK: - RemoteMessageReceiver

public protocol RemoteMessageReceiver: Sendable {

    func registrationToken() async throws -> String

    func registrationTokenRefreshes() -> AsyncStream<String>

    func setDeviceToken(_ token: Data)

}
