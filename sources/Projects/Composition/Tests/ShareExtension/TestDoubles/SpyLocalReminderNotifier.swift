import DataNotification
import Foundation
import Synchronization

// MARK: - SpyLocalReminderNotifier

final class SpyLocalReminderNotifier: LocalReminderNotifier, Sendable {

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

    func requestAuthorization() async -> ReminderAuthorizationStatus {
        counts.withLock { $0.authorizationRequests += 1 }
        return authorized ? .authorized : .declined
    }

    func isAuthorized() async -> Bool {
        authorized
    }

    func schedule(
        _ reminder: ReminderNotification,
        at _: Date,
    ) async {
        counts.withLock { $0.scheduledIdentifiers.append(reminder.identifier) }
    }

    func cancel(identifier: String) async {
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
