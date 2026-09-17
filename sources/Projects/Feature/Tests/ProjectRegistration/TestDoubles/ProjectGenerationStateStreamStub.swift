import DomainIdentifier
import DomainProjectGeneration
import Foundation

actor ProjectGenerationStateStreamStub {

    // MARK: Internal

    func states() async -> AsyncStream<ProjectGenerationState> {
        let (stream, continuation) = AsyncStream<ProjectGenerationState>.makeStream()
        let subscriptionID = UUID()
        continuations[subscriptionID] = continuation
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeSubscription(subscriptionID) }
        }
        subscriptionCount += 1
        continuation.yield(current)
        return stream
    }

    func emit(_ state: ProjectGenerationState) {
        current = state
        yieldCurrent()
    }

    func emit(
        phase: ProjectGenerationPhase,
        projectID: ProjectID,
        repositoryURL: ExternalRepositoryURL = "https://github.com/owner/repo",
        requestedAt: Date = Date(timeIntervalSince1970: 1_800_000_000),
    ) {
        current = ProjectGenerationState(
            requests: [ProjectGenerationRequestState(
                repositoryURL: repositoryURL,
                projectID: projectID,
                requestedAt: requestedAt,
                phase: phase,
            )],
            preparingProjectIDs: [],
        )
        yieldCurrent()
    }

    func finish() {
        for continuation in continuations.values {
            continuation.finish()
        }
        continuations.removeAll()
    }

    func establishedSubscriptionCount() -> Int {
        subscriptionCount
    }

    func activeSubscriptionCount() -> Int {
        continuations.count
    }

    // MARK: Private

    private var current = ProjectGenerationState(requests: [], preparingProjectIDs: [])
    private var continuations = [UUID: AsyncStream<ProjectGenerationState>.Continuation]()
    private var subscriptionCount = 0

    private func yieldCurrent() {
        for continuation in continuations.values {
            continuation.yield(current)
        }
    }

    private func removeSubscription(_ subscriptionID: UUID) {
        continuations[subscriptionID] = nil
    }

}
