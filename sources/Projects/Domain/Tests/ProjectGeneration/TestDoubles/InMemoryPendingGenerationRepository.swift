import Foundation

@testable import DomainProjectGeneration

actor InMemoryPendingGenerationRepository: PendingGenerationRepository {

    // MARK: Lifecycle

    init(state: GenerationState = GenerationState()) {
        self.state = state
    }

    // MARK: Internal

    private(set) var state: GenerationState
    private(set) var reminderProjectIDs = [String]()
    private(set) var finishedProjectIDs = [String]()

    var subscriberCount: Int {
        subscribers.count
    }

    func pendingState() async -> GenerationState {
        state
    }

    func pendingStateChanges() async -> AsyncStream<GenerationState> {
        let (stream, continuation) = AsyncStream<GenerationState>.makeStream()
        let subscriberID = UUID()
        subscribers[subscriberID] = continuation
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeSubscriber(subscriberID) }
        }
        continuation.yield(state)
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
    ) async {
        finishedProjectIDs.append(projectID)
        update(state.finishing(
            projectID: projectID,
            status: status,
            at: finishedAt,
        ))
    }

    func releaseGeneration(repositoryURL: String) async {
        update(state.removing(repositoryURL: repositoryURL))
    }

    func releaseGeneration(projectID: String) async {
        update(state.removing(projectID: projectID))
    }

    func releaseAll() async {
        reminderProjectIDs.removeAll()
        update(GenerationState())
    }

    func enqueueReminder(projectID: String) async {
        guard !reminderProjectIDs.contains(projectID) else { return }
        reminderProjectIDs.append(projectID)
    }

    func drainReminderProjectIDs() async -> [String] {
        defer { reminderProjectIDs.removeAll() }
        return reminderProjectIDs
    }

    // MARK: Private

    private var subscribers = [UUID: AsyncStream<GenerationState>.Continuation]()

    private func update(_ next: GenerationState) {
        state = next
        for continuation in subscribers.values {
            continuation.yield(next)
        }
    }

    private func removeSubscriber(_ subscriberID: UUID) {
        subscribers.removeValue(forKey: subscriberID)
    }

}
