import DataLearningProject
import DomainLearningProject

// MARK: - PendingGenerationReminderStoreAdapter

struct PendingGenerationReminderStoreAdapter: PendingGenerationReminderStore {

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
