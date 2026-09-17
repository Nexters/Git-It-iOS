import Foundation

@testable import DomainLearningProject

actor StubPendingGenerationRepository: PendingGenerationRepository {

    // MARK: Lifecycle

    init(
        state: GenerationState = GenerationState(),
        reminderProjectIDs: [String] = [],
    ) {
        self.state = state
        self.reminderProjectIDs = reminderProjectIDs
    }

    // MARK: Internal

    struct FinishedGeneration: Equatable, Sendable {
        let projectID: String
        let status: GenerationRecord.Status
        let finishedAt: Date
    }

    private(set) var state: GenerationState
    private(set) var reminderProjectIDs: [String]
    private(set) var finishedGenerations = [FinishedGeneration]()

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
        githubRepoURL: String,
        requestedAt: Date,
    ) async -> Bool {
        guard let next = state.beginning(githubRepoURL: githubRepoURL, requestedAt: requestedAt) else { return false }
        update(next)
        return true
    }

    func attachProjectID(
        _ projectID: String,
        toGithubRepoURL githubRepoURL: String,
    ) async {
        update(state.attachingProjectID(projectID, toGithubRepoURL: githubRepoURL))
    }

    func finishGeneration(
        projectID: String,
        status: GenerationRecord.Status,
        finishedAt: Date,
    ) async {
        finishedGenerations.append(FinishedGeneration(projectID: projectID, status: status, finishedAt: finishedAt))
        update(state.finishing(projectID: projectID, status: status, at: finishedAt))
    }

    func releaseGeneration(githubRepoURL: String) async {
        update(state.removing(githubRepoURL: githubRepoURL))
    }

    func releaseGeneration(projectID: String) async {
        update(state.removing(projectID: projectID))
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
