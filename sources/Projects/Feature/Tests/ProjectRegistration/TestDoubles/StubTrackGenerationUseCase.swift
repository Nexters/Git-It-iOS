import DomainLearningProject
import Foundation

actor StubTrackGenerationUseCase: TrackGenerationUseCase {

    // MARK: Internal

    func begin(
        githubRepoURL: String,
        requestedAt: Date,
    ) async -> Bool {
        guard let next = state.beginning(githubRepoURL: githubRepoURL, requestedAt: requestedAt) else {
            return false
        }
        state = next
        yieldCurrent()
        return true
    }

    func attachProjectID(
        _ projectID: String,
        toGithubRepoURL githubRepoURL: String,
    ) async {
        state = state.attachingProjectID(projectID, toGithubRepoURL: githubRepoURL)
        yieldCurrent()
    }

    func end(githubRepoURL: String) async {
        state = state.removing(githubRepoURL: githubRepoURL)
        yieldCurrent()
    }

    func end(projectID: String) async {
        state = state.removing(projectID: projectID)
        yieldCurrent()
    }

    func current() async -> GenerationState {
        state
    }

    func states() async -> AsyncStream<GenerationState> {
        let (stream, continuation) = AsyncStream<GenerationState>.makeStream()
        let subscriptionID = UUID()
        continuations[subscriptionID] = continuation
        continuation.onTermination = { _ in
            Task { await self.removeSubscription(subscriptionID) }
        }
        subscriptionCount += 1
        continuation.yield(state)
        return stream
    }

    func emit(_ outcome: GenerationOutcome) {
        let requestedAt = state.record(projectID: outcome.projectID)?.requestedAt ?? Date()
        let githubRepoURL = state.record(projectID: outcome.projectID)?.githubRepoURL
            ?? "https://github.com/owner/\(outcome.projectID)"
        let remaining = state.records.filter { $0.projectID != outcome.projectID }
        state = GenerationState(records: remaining + [
            GenerationRecord(
                githubRepoURL: githubRepoURL,
                projectID: outcome.projectID,
                requestedAt: requestedAt,
                status: outcome.status == .completed ? .completed : .failed,
                finishedAt: Date(),
            )
        ])
        yieldCurrent()
    }

    func store(_ state: GenerationState) {
        self.state = state
        yieldCurrent()
    }

    func finish() {
        for continuation in continuations.values {
            continuation.finish()
        }
    }

    func hasEstablishedSubscription() -> Bool {
        subscriptionCount > 0
    }

    func establishedSubscriptionCount() -> Int {
        subscriptionCount
    }

    func activeSubscriptionCount() -> Int {
        continuations.count
    }

    // MARK: Private

    private var state = GenerationState()
    private var continuations = [UUID: AsyncStream<GenerationState>.Continuation]()
    private var subscriptionCount = 0

    private func yieldCurrent() {
        for continuation in continuations.values {
            continuation.yield(state)
        }
    }

    private func removeSubscription(_ subscriptionID: UUID) {
        continuations[subscriptionID] = nil
    }

}
