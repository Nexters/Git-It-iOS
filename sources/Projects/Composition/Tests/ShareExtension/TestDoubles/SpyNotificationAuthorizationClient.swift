import Foundation
import InfrastructureLocalNotification
import Synchronization

// MARK: - SpyNotificationAuthorizationClient

final class SpyNotificationAuthorizationClient: NotificationAuthorizationClient, Sendable {

    // MARK: Lifecycle

    init(isAuthorized: Bool) {
        authorized = isAuthorized
    }

    // MARK: Internal

    var authorizationRequestCount: Int {
        counts.withLock { $0.authorizationRequests }
    }

    var scheduledIdentifiers: [String] {
        counts.withLock { $0.scheduledIdentifiers }
    }

    func requestAuthorization() async -> NotificationAuthorizationStatus {
        counts.withLock { $0.authorizationRequests += 1 }
        return authorized ? .authorized : .declined
    }

    func isAuthorized() async -> Bool {
        authorized
    }

    func present(_ request: LocalNotificationRequest) {
        counts.withLock { $0.scheduledIdentifiers.append(request.identifier) }
    }

    func schedule(
        _ request: LocalNotificationRequest,
        at _: Date,
    ) {
        counts.withLock { $0.scheduledIdentifiers.append(request.identifier) }
    }

    func cancel(identifier: String) {
        counts.withLock { state in
            state.scheduledIdentifiers.removeAll { $0 == identifier }
        }
    }

    // MARK: Private

    private struct Counts {
        var authorizationRequests = 0
        var scheduledIdentifiers = [String]()
    }

    private let authorized: Bool
    private let counts = Mutex(Counts())

}
