// MARK: - PendingGenerationReminderStore

public protocol PendingGenerationReminderStore: Sendable {
    func drainProjectIDs() async -> [String]
}
