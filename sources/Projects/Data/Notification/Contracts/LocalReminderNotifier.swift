import Foundation

// MARK: - LocalReminderNotifier

public protocol LocalReminderNotifier: Sendable {

    func requestAuthorization() async -> ReminderAuthorizationStatus

    func authorizationSetting() async -> ReminderAuthorizationSetting

}
