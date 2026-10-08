import Foundation

// MARK: - NotificationAuthorizationClient

public protocol NotificationAuthorizationClient: Sendable {

    func requestAuthorization() async -> NotificationAuthorizationStatus

    func authorizationSetting() async -> NotificationAuthorizationSetting

}
