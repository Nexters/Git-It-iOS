import Foundation

public struct TrackGeneration: TrackGenerationUseCase, Sendable {

    // MARK: Lifecycle

    public init(
        pendingGenerations: any PendingGenerationRepository,
        outcomeRepository: any GenerationOutcomeRepository,
        now: @escaping @Sendable () -> Date = Date.init,
    ) {
        self.pendingGenerations = pendingGenerations
        coordinator = GenerationStateCoordinator(
            pendingGenerations: pendingGenerations,
            outcomeRepository: outcomeRepository,
            now: now,
        )
    }

    // MARK: Public

    public func begin(
        githubRepoURL: String,
        requestedAt: Date,
    ) async -> Bool {
        await coordinator.ensureStarted()
        return await pendingGenerations.beginGeneration(githubRepoURL: githubRepoURL, requestedAt: requestedAt)
    }

    public func attachProjectID(
        _ projectID: String,
        toGithubRepoURL githubRepoURL: String,
    ) async {
        await coordinator.ensureStarted()
        await pendingGenerations.attachProjectID(projectID, toGithubRepoURL: githubRepoURL)
    }

    public func end(githubRepoURL: String) async {
        await coordinator.ensureStarted()
        await pendingGenerations.releaseGeneration(githubRepoURL: githubRepoURL)
    }

    public func end(projectID: String) async {
        await coordinator.ensureStarted()
        await pendingGenerations.releaseGeneration(projectID: projectID)
    }

    public func current() async -> GenerationState {
        await coordinator.ensureStarted()
        return await pendingGenerations.pendingState()
    }

    public func states() async -> AsyncStream<GenerationState> {
        await coordinator.ensureStarted()
        return await pendingGenerations.pendingStateChanges()
    }

    // MARK: Private

    private let pendingGenerations: any PendingGenerationRepository
    private let coordinator: GenerationStateCoordinator

}
