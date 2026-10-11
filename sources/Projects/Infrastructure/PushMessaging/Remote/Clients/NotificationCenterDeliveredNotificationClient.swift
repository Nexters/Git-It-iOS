import Foundation
import UserNotifications

// MARK: - NotificationCenterDeliveredNotificationClient

public struct NotificationCenterDeliveredNotificationClient: DeliveredNotificationClient {

    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public func deliveredRemoteNotifications() async -> [DeliveredRemoteNotification] {
        await UNUserNotificationCenter.current().deliveredNotifications()
            .filter { $0.request.trigger is UNPushNotificationTrigger }
            .map { notification in
                DeliveredRemoteNotification(
                    payload: RemoteNotificationPayload(userInfo: notification.request.content.userInfo).userInfoStrings,
                    deliveredAt: notification.date,
                )
            }
    }

}
