import DataNotification
import DomainLearningProject
import Foundation

// MARK: - GenerationReminderSchedulerAdapter

struct GenerationReminderSchedulerAdapter: GenerationReminderScheduler {

    // MARK: Lifecycle

    init(
        reminderNotifier: any LocalReminderNotifier,
        title: String,
        body: String,
    ) {
        self.reminderNotifier = reminderNotifier
        self.title = title
        self.body = body
    }

    // MARK: Internal

    func isAuthorized() async -> Bool {
        await reminderNotifier.isAuthorized()
    }

    func schedule(
        identifier: String,
        at date: Date,
    ) async {
        await reminderNotifier.schedule(
            ReminderNotification(
                identifier: identifier,
                title: title,
                body: body,
            ),
            at: date,
        )
    }

    // MARK: Private

    private let reminderNotifier: any LocalReminderNotifier
    private let title: String
    private let body: String

}
