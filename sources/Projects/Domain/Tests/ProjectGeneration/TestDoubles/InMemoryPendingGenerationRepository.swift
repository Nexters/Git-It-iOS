import DomainUseCaseDependency
import Foundation

@testable import DomainUseCaseInterface

actor InMemoryPendingGenerationRepository: PendingGenerationRepository {

    // MARK: Lifecycle

    init(
        state: GenerationState = GenerationState(),
        confirmationFailure: (any Error)? = nil,
        retentionLimit: TimeInterval = GenerationWaitPolicy.standard.retentionLimit,
        now: @escaping @Sendable () -> Date,
    ) {
        self.state = state
        self.confirmationFailure = confirmationFailure
        self.retentionLimit = retentionLimit
        self.now = now
    }

    // MARK: Internal

    private(set) var state: GenerationState
    private(set) var finishedProjectIDs = [String]()

    var subscriberCount: Int {
        subscribers.count
    }

    func pendingState() async -> GenerationState {
        visibleState()
    }

    func confirmedPendingState() async throws -> GenerationState {
        if let confirmationFailure {
            throw confirmationFailure
        }
        return visibleState()
    }

    func pendingStateChanges() async -> AsyncStream<GenerationState> {
        let (stream, continuation) = AsyncStream<GenerationState>.makeStream()
        let subscriberID = UUID()
        subscribers[subscriberID] = continuation
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeSubscriber(subscriberID) }
        }
        continuation.yield(visibleState())
        return stream
    }

    func beginGeneration(
        repositoryURL: String,
        requestedAt: Date,
    ) async -> Bool {
        guard
            let next = state.beginning(
                repositoryURL: repositoryURL,
                requestedAt: requestedAt,
            )
        else { return false }
        update(next)
        return true
    }

    func attachProjectID(
        _ projectID: String,
        toRepositoryURL repositoryURL: String,
    ) async {
        update(state.attachingProjectID(
            projectID,
            toRepositoryURL: repositoryURL,
        ))
    }

    func finishGeneration(
        projectID: String,
        status: GenerationRecord.Status,
        finishedAt: Date,
    ) async -> Bool {
        finishedProjectIDs.append(projectID)
        guard visibleState().records.contains(where: { $0.projectID == projectID }) else { return false }
        update(state.finishing(
            projectID: projectID,
            status: status,
            at: finishedAt,
        ))
        return true
    }

    func releaseGeneration(repositoryURL: String) async {
        update(state.removing(repositoryURL: repositoryURL))
    }

    func releaseGeneration(projectID: String) async {
        update(state.removing(projectID: projectID))
    }

    func releaseAll() async {
        update(GenerationState())
    }

    func replaceStateSilently(_ next: GenerationState) {
        state = next
    }

    // MARK: Private

    private let confirmationFailure: (any Error)?
    private let retentionLimit: TimeInterval
    private let now: @Sendable () -> Date
    private var subscribers = [UUID: AsyncStream<GenerationState>.Continuation]()

    private func visibleState() -> GenerationState {
        state.purgingExpired(
            now: now(),
            retentionLimit: retentionLimit,
        )
    }

    private func update(_ next: GenerationState) {
        state = next
        let visible = visibleState()
        for continuation in subscribers.values {
            continuation.yield(visible)
        }
    }

    private func removeSubscriber(_ subscriberID: UUID) {
        subscribers.removeValue(forKey: subscriberID)
    }

}
