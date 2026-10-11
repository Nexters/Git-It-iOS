import InfrastructurePushMessaging

// MARK: - StubDeliveredNotificationClient

struct StubDeliveredNotificationClient: DeliveredNotificationClient {

    // MARK: Lifecycle

    init(notifications: [DeliveredRemoteNotification]) {
        self.notifications = notifications
    }

    // MARK: Internal

    func deliveredRemoteNotifications() async -> [DeliveredRemoteNotification] {
        notifications
    }

    // MARK: Private

    private let notifications: [DeliveredRemoteNotification]

}
