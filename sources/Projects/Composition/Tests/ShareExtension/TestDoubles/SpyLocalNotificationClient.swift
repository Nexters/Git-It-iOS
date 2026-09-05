import Foundation
import InfrastructureLocalNotification
import Synchronization

// MARK: - SpyLocalNotificationClient

/// 권한 요청이 발생하지 않는지 확인하기 위해 호출 횟수를 기록한다.
final class SpyLocalNotificationClient: LocalNotificationClient, Sendable {

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

    func requestAuthorization() async -> LocalNotificationAuthorizationOutcome {
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
        at date: Date,
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
