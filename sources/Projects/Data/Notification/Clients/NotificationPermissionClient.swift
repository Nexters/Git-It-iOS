import Foundation
import InfrastructureLocalNotification

// MARK: - NotificationPermissionClient

struct NotificationPermissionClient: NotificationPermissionRequester {

    // MARK: Lifecycle

    init(authorizationClient: any NotificationAuthorizationClient) {
        self.authorizationClient = authorizationClient
    }

    // MARK: Internal

    func requestAuthorization() async -> NotificationPermissionRequestResult {
        switch await authorizationClient.requestAuthorization() {
        case .authorized: .authorized
        case .declined: .declined
        case .previouslyDenied: .previouslyDenied
        }
    }

    func authorizationSetting() async -> NotificationPermissionSetting {
        switch await authorizationClient.authorizationSetting() {
        case .notDetermined: .notDetermined
        case .authorized: .authorized
        case .denied: .denied
        }
    }

    // MARK: Private

    private let authorizationClient: any NotificationAuthorizationClient

}
