import DataLearningProject
import DomainLearningProject
import Foundation

// MARK: - PendingGenerationRepositoryAdapter

struct PendingGenerationRepositoryAdapter: PendingGenerationRepository {

    // MARK: Lifecycle

    init(
        store: LocalPendingGenerationStore,
        waitPolicy: GenerationWaitPolicy = .standard,
        now: @escaping @Sendable () -> Date = Date.init,
    ) {
        self.store = store
        self.waitPolicy = waitPolicy
        self.now = now
    }

    // MARK: Internal

    func pendingState() async -> GenerationState {
        Self.purged(Self.state(from: await store.state()), waitPolicy: waitPolicy, now: now())
    }

    func pendingStateChanges() async -> AsyncStream<GenerationState> {
        let changes = await store.stateChanges()
        let waitPolicy = waitPolicy
        let now = now
        return AsyncStream { continuation in
            let task = Task {
                for await dto in changes {
                    continuation.yield(Self.purged(Self.state(from: dto), waitPolicy: waitPolicy, now: now()))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    func beginGeneration(
        githubRepoURL: String,
        requestedAt: Date,
    ) async -> Bool {
        await modify { $0.beginning(githubRepoURL: githubRepoURL, requestedAt: requestedAt) }
    }

    func attachProjectID(
        _ projectID: String,
        toGithubRepoURL githubRepoURL: String,
    ) async {
        await modify { $0.attachingProjectID(projectID, toGithubRepoURL: githubRepoURL) }
    }

    func finishGeneration(
        projectID: String,
        status: GenerationRecord.Status,
        finishedAt: Date,
    ) async {
        await modify { $0.finishing(projectID: projectID, status: status, at: finishedAt) }
    }

    func releaseGeneration(githubRepoURL: String) async {
        await modify { $0.removing(githubRepoURL: githubRepoURL) }
    }

    func releaseGeneration(projectID: String) async {
        await modify { $0.removing(projectID: projectID) }
    }

    func enqueueReminder(projectID: String) async {
        await store.appendReminder(projectID: projectID, requestedAt: now())
    }

    func drainReminderProjectIDs() async -> [String] {
        await store.drainReminderProjectIDs()
    }

    // MARK: Private

    private static let inProgressStatus = "inProgress"
    private static let completedStatus = "completed"
    private static let failedStatus = "failed"

    private let store: LocalPendingGenerationStore
    private let waitPolicy: GenerationWaitPolicy
    private let now: @Sendable () -> Date

    private static func purged(
        _ state: GenerationState,
        waitPolicy: GenerationWaitPolicy,
        now: Date,
    ) -> GenerationState {
        state.purgingExpired(now: now, retentionLimit: waitPolicy.retentionLimit)
    }

    private static func state(from dto: GenerationStateDTO) -> GenerationState {
        GenerationState(records: dto.records.compactMap(record(from:)))
    }

    private static func dto(from state: GenerationState) -> GenerationStateDTO {
        GenerationStateDTO(records: state.records.map(dto(from:)))
    }

    private static func record(from dto: GenerationRecordDTO) -> GenerationRecord? {
        guard let status = status(from: dto.status) else { return nil }
        return GenerationRecord(
            githubRepoURL: dto.githubRepoURL,
            projectID: dto.projectID,
            requestedAt: dto.requestedAt,
            status: status,
            finishedAt: dto.finishedAt,
        )
    }

    private static func status(from rawValue: String) -> GenerationRecord.Status? {
        switch rawValue {
        case inProgressStatus:
            .inProgress

        case completedStatus:
            .completed

        case failedStatus:
            .failed

        default:
            nil
        }
    }

    private static func dto(from record: GenerationRecord) -> GenerationRecordDTO {
        GenerationRecordDTO(
            githubRepoURL: record.githubRepoURL,
            projectID: record.projectID,
            requestedAt: record.requestedAt,
            status: rawValue(from: record.status),
            finishedAt: record.finishedAt,
        )
    }

    private static func rawValue(from status: GenerationRecord.Status) -> String {
        switch status {
        case .inProgress:
            inProgressStatus

        case .completed:
            completedStatus

        case .failed:
            failedStatus
        }
    }

    @discardableResult
    private func modify(_ transition: @escaping @Sendable (GenerationState) -> GenerationState?) async -> Bool {
        let waitPolicy = waitPolicy
        let now = now()
        let written = await store.modifyState { dto in
            let current = Self.purged(Self.state(from: dto), waitPolicy: waitPolicy, now: now)
            return transition(current).map(Self.dto(from:))
        }
        return written != nil
    }

}
