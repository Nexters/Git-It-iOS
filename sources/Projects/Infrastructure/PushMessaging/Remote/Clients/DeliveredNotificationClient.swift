// MARK: - DeliveredNotificationClient

public protocol DeliveredNotificationClient: Sendable {
    func deliveredRemoteNotifications() async -> [DeliveredRemoteNotification]
}
