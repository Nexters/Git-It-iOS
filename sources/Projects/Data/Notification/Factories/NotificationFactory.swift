import InfrastructureLocalNotification

// MARK: - NotificationFactory

public enum NotificationFactory {

    // MARK: Public

    public static func localReminderNotifier() -> any LocalReminderNotifier {
        ReminderNotificationClient(authorizationClient: LocalNotificationAuthorizationClient())
    }

    public static func remoteMessageReceiver() -> any RemoteMessageReceiver {
        RemoteMessageClient()
    }

}
