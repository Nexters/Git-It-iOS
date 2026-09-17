import Foundation
import InfrastructureLocalNotification
import Synchronization

// MARK: - SpyNotificationAuthorizationClient

final class SpyNotificationAuthorizationClient: NotificationAuthorizationClient, Sendable {

    // MARK: Lifecycle

    init(
        status: NotificationAuthorizationStatus = .authorized,
        isAuthorized: Bool = true,
        setting: NotificationAuthorizationSetting = .authorized,
    ) {
        self.status = status
        authorized = isAuthorized
        self.setting = setting
    }

    // MARK: Internal

    struct ScheduledRequest: Equatable {
        let request: LocalNotificationRequest
        let date: Date
    }

    var authorizationRequestCount: Int {
        state.withLock { $0.authorizationRequests }
    }

    var scheduledRequests: [ScheduledRequest] {
        state.withLock { $0.scheduledRequests }
    }

    var presentedRequests: [LocalNotificationRequest] {
        state.withLock { $0.presentedRequests }
    }

    var cancelledIdentifiers: [String] {
        state.withLock { $0.cancelledIdentifiers }
    }

    func requestAuthorization() async -> NotificationAuthorizationStatus {
        state.withLock { $0.authorizationRequests += 1 }
        return status
    }

    func isAuthorized() async -> Bool {
        authorized
    }

    func authorizationSetting() async -> NotificationAuthorizationSetting {
        setting
    }

    func present(_ request: LocalNotificationRequest) {
        state.withLock { $0.presentedRequests.append(request) }
    }

    func schedule(
        _ request: LocalNotificationRequest,
        at date: Date,
    ) {
        state.withLock { $0.scheduledRequests.append(ScheduledRequest(request: request, date: date)) }
    }

    func cancel(identifier: String) {
        state.withLock { $0.cancelledIdentifiers.append(identifier) }
    }

    // MARK: Private

    private struct State {
        var authorizationRequests = 0
        var scheduledRequests = [ScheduledRequest]()
        var presentedRequests = [LocalNotificationRequest]()
        var cancelledIdentifiers = [String]()
    }

    private let status: NotificationAuthorizationStatus
    private let authorized: Bool
    private let setting: NotificationAuthorizationSetting
    private let state = Mutex(State())

}
