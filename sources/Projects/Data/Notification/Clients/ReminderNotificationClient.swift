import Foundation
import InfrastructureLocalNotification

// MARK: - ReminderNotificationClient

struct ReminderNotificationClient: LocalReminderNotifier {

    // MARK: Lifecycle

    init(authorizationClient: any NotificationAuthorizationClient) {
        self.authorizationClient = authorizationClient
    }

    // MARK: Internal

    func requestAuthorization() async -> ReminderAuthorizationStatus {
        switch await authorizationClient.requestAuthorization() {
        case .authorized: .authorized
        case .declined: .declined
        case .previouslyDenied: .previouslyDenied
        }
    }

    func isAuthorized() async -> Bool {
        await authorizationClient.isAuthorized()
    }

    func authorizationSetting() async -> ReminderAuthorizationSetting {
        switch await authorizationClient.authorizationSetting() {
        case .notDetermined: .notDetermined
        case .authorized: .authorized
        case .denied: .denied
        }
    }

    func schedule(
        _ reminder: ReminderNotification,
        at date: Date,
    ) async {
        authorizationClient.schedule(
            LocalNotificationRequest(
                identifier: reminder.identifier,
                title: reminder.title,
                body: reminder.body,
            ),
            at: date,
        )
    }

    func cancel(identifier: String) async {
        authorizationClient.cancel(identifier: identifier)
    }

    // MARK: Private

    private let authorizationClient: any NotificationAuthorizationClient

}
