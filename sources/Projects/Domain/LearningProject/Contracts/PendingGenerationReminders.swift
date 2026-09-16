// MARK: - PendingGenerationReminders

public protocol PendingGenerationReminders: Sendable {
    func drainProjectIDs() async -> [String]
}
