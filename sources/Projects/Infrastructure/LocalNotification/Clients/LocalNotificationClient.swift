import Foundation

// MARK: - LocalNotificationClient

public protocol LocalNotificationClient: Sendable {

    func requestAuthorization() async -> LocalNotificationAuthorizationOutcome

    func isAuthorized() async -> Bool

    func present(_ request: LocalNotificationRequest)

    func schedule(
        _ request: LocalNotificationRequest,
        at date: Date,
    )

    func cancel(identifier: String)

}
