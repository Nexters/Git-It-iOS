import Foundation
import InfrastructureStorage

// MARK: - PendingGenerationReminderCoding

public struct PendingGenerationReminderCoding: Sendable {

    // MARK: Lifecycle

    public init(userDefaults: UserDefaults) {
        store = UserDefaultsStore<[Entry]>(
            namespace: AppGroupUserDefaults.sharedSessionNamespace,
            userDefaults: userDefaults,
        )
    }

    // MARK: Public

    public static let pendingGenerationRemindersKey = "pendingGenerationReminders"
    public static let pendingReminderLimit = 32

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
        if entries.count > Self.pendingReminderLimit {
            entries.removeFirst(entries.count - Self.pendingReminderLimit)
        }
        await store.store(
            entries,
            forKey: Self.pendingGenerationRemindersKey,
        )
    }

    public func drainProjectIDs() async -> [String] {
        let entries = await loadEntries()
        guard !entries.isEmpty else { return [] }
        await store.removeValue(forKey: Self.pendingGenerationRemindersKey)
        return entries.map(\.projectID)
    }

    // MARK: Private

    private struct Entry: Codable, Sendable {
        let projectID: String
        let requestedAt: Date
    }

    private let store: UserDefaultsStore<[Entry]>

    private func loadEntries() async -> [Entry] {
        await store.value(forKey: Self.pendingGenerationRemindersKey) ?? []
    }

}
