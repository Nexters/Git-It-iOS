import DataNotification
import DomainAppSetting

// MARK: - AppSettingNotificationAuthorizationAdapter

public struct AppSettingNotificationAuthorizationAdapter: NotificationAuthorization {

    // MARK: Lifecycle

    public init(reminderNotifier: any LocalReminderNotifier) {
        self.reminderNotifier = reminderNotifier
    }

    // MARK: Public

    public func status() async -> NotificationAuthorizationStatus {
        switch await reminderNotifier.authorizationSetting() {
        case .notDetermined: .notDetermined
        case .authorized: .authorized
        case .denied: .denied
        }
    }

    public func requestAuthorization() async -> NotificationAuthorizationStatus {
        switch await reminderNotifier.requestAuthorization() {
        case .authorized: .authorized
        case .declined,
             .previouslyDenied: .denied
        }
    }

    // MARK: Private

    private let reminderNotifier: any LocalReminderNotifier

}
