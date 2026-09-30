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

    func authorizationSetting() async -> ReminderAuthorizationSetting {
        switch await authorizationClient.authorizationSetting() {
        case .notDetermined: .notDetermined
        case .authorized: .authorized
        case .denied: .denied
        }
    }

    // MARK: Private

    private let authorizationClient: any NotificationAuthorizationClient

}
