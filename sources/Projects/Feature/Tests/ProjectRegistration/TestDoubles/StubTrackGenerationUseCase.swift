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
        self.continuation = continuation
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

    func finish() {
        continuation?.finish()
    }

    func hasEstablishedSubscription() -> Bool {
        continuation != nil
    }

    func establishedSubscriptionCount() -> Int {
        subscriptionCount
    }

    // MARK: Private

    private var state = GenerationState()
    private var continuation: AsyncStream<GenerationState>.Continuation?
    private var subscriptionCount = 0

    private func yieldCurrent() {
        continuation?.yield(state)
    }

}
