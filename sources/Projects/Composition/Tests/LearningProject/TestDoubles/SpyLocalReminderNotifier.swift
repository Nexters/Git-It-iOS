import DataNotification
import Foundation

// MARK: - SpyLocalReminderNotifier

actor SpyLocalReminderNotifier: LocalReminderNotifier {

    private(set) var scheduledIdentifiers = [String]()
    private(set) var cancelledIdentifiers = [String]()

    func requestAuthorization() async -> ReminderAuthorizationStatus {
        .authorized
    }

    func isAuthorized() async -> Bool {
        true
    }

    func authorizationSetting() async -> ReminderAuthorizationSetting {
        .authorized
    }

    func schedule(
        _ reminder: ReminderNotification,
        at _: Date,
    ) async {
        scheduledIdentifiers.append(reminder.identifier)
    }

    func cancel(identifier: String) async {
        cancelledIdentifiers.append(identifier)
    }

}
