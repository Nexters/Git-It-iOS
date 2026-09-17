import DataShared
import Foundation
import Synchronization

// MARK: - LocalPendingGenerationStore

public actor LocalPendingGenerationStore {

    // MARK: Lifecycle

    public init(storage: any KeyValueStorage) {
        self.storage = storage
    }

    // MARK: Public

    public static let namespace = "com.nexters.hytime.gitit.sharedSession"
    public static let stateKey = "generationState"
    public static let pendingGenerationRemindersKey = "pendingGenerationReminders"
    public static let pendingReminderLimit = 32

    public func state() async -> GenerationStateDTO {
        await exclusively { await self.loadState() }
    }

    public func stateChanges() async -> AsyncStream<GenerationStateDTO> {
        await exclusively { await self.subscribe() }
    }

    @discardableResult
    public func modifyState(
        _ transform: @escaping @Sendable (GenerationStateDTO) -> GenerationStateDTO?
    ) async -> GenerationStateDTO? {
        await exclusively {
            guard let next = transform(await self.loadState()) else { return nil }
            await self.storage.setValue(next, forKey: Self.stateKey)
            self.broadcast(next)
            return next
        }
    }

    public func appendReminder(
        projectID: String,
        requestedAt: Date,
    ) async {
        await exclusively {
            var entries = await self.loadReminderEntries()
            guard !entries.contains(where: { $0.projectID == projectID }) else { return }
            entries.append(ReminderEntry(projectID: projectID, requestedAt: requestedAt))
            if entries.count > Self.pendingReminderLimit {
                entries.removeFirst(entries.count - Self.pendingReminderLimit)
            }
            await self.storage.setValue(entries, forKey: Self.pendingGenerationRemindersKey)
        }
    }

    public func drainReminderProjectIDs() async -> [String] {
        await exclusively {
            let entries = await self.loadReminderEntries()
            guard !entries.isEmpty else { return [] }
            await self.storage.removeValue(forKey: Self.pendingGenerationRemindersKey)
            return entries.map(\.projectID)
        }
    }

    // MARK: Private

    private struct ReminderEntry: Codable, Sendable {
        let projectID: String
        let requestedAt: Date
    }

    private let storage: any KeyValueStorage
    private let subscribers = Mutex([UUID: AsyncStream<GenerationStateDTO>.Continuation]())
    private var lastOperation: Task<Void, Never>?

    private func exclusively<Result: Sendable>(
        _ operation: @escaping @Sendable () async -> Result
    ) async -> Result {
        let previous = lastOperation
        let task = Task<Result, Never> {
            await previous?.value
            return await operation()
        }
        lastOperation = Task { _ = await task.value }
        return await task.value
    }

    private func loadState() async -> GenerationStateDTO {
        await storage.value(GenerationStateDTO.self, forKey: Self.stateKey) ?? GenerationStateDTO(records: [])
    }

    private func loadReminderEntries() async -> [ReminderEntry] {
        await storage.value([ReminderEntry].self, forKey: Self.pendingGenerationRemindersKey) ?? []
    }

    private func subscribe() async -> AsyncStream<GenerationStateDTO> {
        let (stream, continuation) = AsyncStream.makeStream(of: GenerationStateDTO.self)
        let subscriberID = UUID()
        subscribers.withLock { $0[subscriberID] = continuation }
        continuation.onTermination = { [weak self] _ in
            _ = self?.subscribers.withLock { $0.removeValue(forKey: subscriberID) }
        }
        continuation.yield(await loadState())
        return stream
    }

    private nonisolated func broadcast(_ state: GenerationStateDTO) {
        let continuations = subscribers.withLock { Array($0.values) }
        for continuation in continuations {
            continuation.yield(state)
        }
    }

}
