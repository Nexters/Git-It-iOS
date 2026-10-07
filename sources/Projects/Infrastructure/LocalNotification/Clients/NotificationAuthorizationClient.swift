import Foundation

// MARK: - NotificationAuthorizationClient

public protocol NotificationAuthorizationClient: Sendable {

    func requestAuthorization() async -> NotificationAuthorizationStatus

    func isAuthorized() async -> Bool

    func present(_ request: LocalNotificationRequest)

    func schedule(
        _ request: LocalNotificationRequest,
        at date: Date,
    )

    func cancel(identifier: String)

}
