import Foundation
import InfrastructureLocalNotification
import Synchronization

// MARK: - SpyNotificationAuthorizationClient

final class SpyNotificationAuthorizationClient: NotificationAuthorizationClient, Sendable {

    // MARK: Lifecycle

    init(
        status: NotificationAuthorizationStatus = .authorized,
        setting: NotificationAuthorizationSetting = .authorized,
    ) {
        self.status = status
        self.setting = setting
    }

    // MARK: Internal

    var authorizationRequestCount: Int {
        state.withLock { $0.authorizationRequests }
    }

    func requestAuthorization() async -> NotificationAuthorizationStatus {
        state.withLock { $0.authorizationRequests += 1 }
        return status
    }

    func authorizationSetting() async -> NotificationAuthorizationSetting {
        setting
    }

    // MARK: Private

    private struct State {
        var authorizationRequests = 0
    }

    private let status: NotificationAuthorizationStatus
    private let setting: NotificationAuthorizationSetting
    private let state = Mutex(State())

}
