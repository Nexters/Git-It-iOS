import InfrastructureLocalNotification
import InfrastructurePushMessaging

// MARK: - NotificationFactory

public enum NotificationFactory {

    // MARK: Public

    public static func localReminderNotifier() -> any LocalReminderNotifier {
        ReminderNotificationClient(authorizationClient: LocalNotificationAuthorizationClient())
    }

    public static func remoteMessageReceiver() -> any RemoteMessageReceiver {
        RemoteMessageClient()
    }

    public static func deliveredRemoteMessageReader() -> any DeliveredRemoteMessageReader {
        DeliveredRemoteMessageClient(notificationClient: NotificationCenterDeliveredNotificationClient())
    }

}
