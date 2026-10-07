import Foundation

// MARK: - LocalReminderNotifier

public protocol LocalReminderNotifier: Sendable {

    func requestAuthorization() async -> ReminderAuthorizationStatus

    func isAuthorized() async -> Bool

    func authorizationSetting() async -> ReminderAuthorizationSetting

    func schedule(
        _ reminder: ReminderNotification,
        at date: Date,
    ) async

    func cancel(identifier: String) async

}
