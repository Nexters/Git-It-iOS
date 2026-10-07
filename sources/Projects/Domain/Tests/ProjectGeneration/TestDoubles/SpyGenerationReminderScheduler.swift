import Foundation

@testable import DomainProjectGeneration

actor SpyGenerationReminderScheduler: GenerationReminderScheduler {

    // MARK: Lifecycle

    init(isAuthorized: Bool = true) {
        authorized = isAuthorized
    }

    // MARK: Internal

    struct ScheduledReminder: Equatable, Sendable {
        let reminder: GenerationReminder
        let date: Date
    }

    private(set) var scheduledReminders = [ScheduledReminder]()

    func isAuthorized() async -> Bool {
        authorized
    }

    func schedule(
        _ reminder: GenerationReminder,
        at date: Date,
    ) async {
        scheduledReminders.append(ScheduledReminder(reminder: reminder, date: date))
    }

    // MARK: Private

    private let authorized: Bool

}
