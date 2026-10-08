import DataShared
import Foundation
import os
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

    public func state() async -> GenerationStateDTO {
        await exclusively { await self.loadState() }
    }

    public func verifiedState() async throws(KeyValueStorageError) -> GenerationStateDTO {
        try await exclusively { await self.loadVerifiedState() }.get()
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
            await self.storage.setValue(
                next,
                forKey: Self.stateKey,
            )
            Self.logStoredState(next)
            self.broadcast(next)
            return next
        }
    }

    // MARK: Private

    private static let logger = Logger(
        subsystem: "com.nexters.hytime.gitit",
        category: "LocalPendingGenerationStore",
    )

    private let storage: any KeyValueStorage
    private let subscribers = Mutex([UUID: AsyncStream<GenerationStateDTO>.Continuation]())
    private var lastOperation: Task<Void, Never>?

    private static func logStoredState(_ state: GenerationStateDTO) {
        let counts = Dictionary(
            grouping: state.records,
            by: \.status,
        ).mapValues(\.count)
        let summary = counts.keys.sorted().map { "\($0)=\(counts[$0] ?? 0)" }.joined(separator: " ")
        logger.debug("생성 기록 저장: \(summary, privacy: .public)")
    }

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
        await storage.value(
            GenerationStateDTO.self,
            forKey: Self.stateKey,
        ) ?? GenerationStateDTO(records: [])
    }

    private func loadVerifiedState() async -> Result<GenerationStateDTO, KeyValueStorageError> {
        do {
            let state = try await storage.verifiedValue(
                GenerationStateDTO.self,
                forKey: Self.stateKey,
            )
            return .success(state ?? GenerationStateDTO(records: []))
        } catch {
            return .failure(error)
        }
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
