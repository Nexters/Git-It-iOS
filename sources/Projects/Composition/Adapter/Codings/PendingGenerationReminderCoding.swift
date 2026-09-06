import Foundation
import InfrastructureStorage

// MARK: - PendingGenerationReminderCoding

public struct PendingGenerationReminderCoding: Sendable {

    // MARK: Lifecycle

    public init(userDefaults: UserDefaults) {
        store = UserDefaultsStore<[Entry]>(
            namespace: SharedSessionLayout.namespace,
            userDefaults: userDefaults,
        )
    }

    // MARK: Public

    public func append(
        projectID: String,
        requestedAt: Date = Date(),
    ) async {
        var entries = await loadEntries()
        guard !entries.contains(where: { $0.projectID == projectID }) else { return }
        entries.append(
            Entry(
                projectID: projectID,
                requestedAt: requestedAt,
            )
        )
        if entries.count > SharedSessionLayout.pendingReminderLimit {
            entries.removeFirst(entries.count - SharedSessionLayout.pendingReminderLimit)
        }
        await store.store(
            entries,
            forKey: SharedSessionLayout.pendingGenerationRemindersKey,
        )
    }

    public func drainProjectIDs() async -> [String] {
        let entries = await loadEntries()
        guard !entries.isEmpty else { return [] }
        await store.removeValue(forKey: SharedSessionLayout.pendingGenerationRemindersKey)
        return entries.map(\.projectID)
    }

    // MARK: Private

    private struct Entry: Codable, Sendable {
        let projectID: String
        let requestedAt: Date
    }

    private let store: UserDefaultsStore<[Entry]>

    private func loadEntries() async -> [Entry] {
        await store.value(forKey: SharedSessionLayout.pendingGenerationRemindersKey) ?? []
    }

}
