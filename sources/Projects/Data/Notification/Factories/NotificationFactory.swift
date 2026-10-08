import InfrastructureLocalNotification
import InfrastructurePushMessaging

// MARK: - NotificationFactory

public enum NotificationFactory {

    // MARK: Public

    public static func notificationPermissionRequester() -> any NotificationPermissionRequester {
        NotificationPermissionClient(authorizationClient: LocalNotificationAuthorizationClient())
    }

    public static func remoteMessageReceiver() -> any RemoteMessageReceiver {
        RemoteMessageClient()
    }

    public static func deliveredRemoteMessageReader() -> any DeliveredRemoteMessageReader {
        DeliveredRemoteMessageClient(notificationClient: NotificationCenterDeliveredNotificationClient())
    }

}
