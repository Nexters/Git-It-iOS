import DataLearningProject
import DomainLearningProject

// MARK: - PendingGenerationRemindersAdapter

struct PendingGenerationRemindersAdapter: PendingGenerationReminders {

    // MARK: Lifecycle

    init(coding: PendingGenerationReminderCoding) {
        self.coding = coding
    }

    // MARK: Internal

    func drainProjectIDs() async -> [String] {
        await coding.drainProjectIDs()
    }

    // MARK: Private

    private let coding: PendingGenerationReminderCoding

}
