import Foundation

// MARK: - NotificationAuthorizationClient

public protocol NotificationAuthorizationClient: Sendable {

    func requestAuthorization() async -> NotificationAuthorizationStatus

    func isAuthorized() async -> Bool

    func authorizationSetting() async -> NotificationAuthorizationSetting

    func present(_ request: LocalNotificationRequest)

    func schedule(
        _ request: LocalNotificationRequest,
        at date: Date,
    )

    func cancel(identifier: String)

}
