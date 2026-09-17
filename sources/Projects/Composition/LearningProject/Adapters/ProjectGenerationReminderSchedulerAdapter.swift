import DataNotification
import DomainProjectGeneration
import Foundation

// MARK: - ProjectGenerationReminderSchedulerAdapter

public struct ProjectGenerationReminderSchedulerAdapter: GenerationReminderScheduler {

    // MARK: Lifecycle

    public init(
        reminderNotifier: any LocalReminderNotifier,
        completedTitle: String,
        completedBody: String,
        failedTitle: String,
        failedBody: String,
    ) {
        self.reminderNotifier = reminderNotifier
        self.completedTitle = completedTitle
        self.completedBody = completedBody
        self.failedTitle = failedTitle
        self.failedBody = failedBody
    }

    // MARK: Public

    public func isAuthorized() async -> Bool {
        await reminderNotifier.isAuthorized()
    }

    public func schedule(
        _ reminder: GenerationReminder,
        at date: Date,
    ) async {
        await reminderNotifier.schedule(
            ReminderNotification(
                identifier: identifier(for: reminder),
                title: title(for: reminder.kind),
                body: body(for: reminder.kind),
            ),
            at: date,
        )
    }

    // MARK: Private

    private let reminderNotifier: any LocalReminderNotifier
    private let completedTitle: String
    private let completedBody: String
    private let failedTitle: String
    private let failedBody: String

    private func identifier(for reminder: GenerationReminder) -> String {
        switch reminder.kind {
        case .completed: "generation-completed-\(reminder.projectID)"
        case .failed: "generation-failed-\(reminder.projectID)"
        @unknown default: "generation-completed-\(reminder.projectID)"
        }
    }

    private func title(for kind: GenerationReminder.Kind) -> String {
        switch kind {
        case .completed: completedTitle
        case .failed: failedTitle
        @unknown default: completedTitle
        }
    }

    private func body(for kind: GenerationReminder.Kind) -> String {
        switch kind {
        case .completed: completedBody
        case .failed: failedBody
        @unknown default: completedBody
        }
    }

}
