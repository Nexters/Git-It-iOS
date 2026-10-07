import Foundation

public struct TrackGeneration: TrackGenerationUseCase, Sendable {

    // MARK: Lifecycle

    public init(
        stateRepository: any GenerationStateRepository,
        outcomeRepository: any GenerationOutcomeRepository,
        waitPolicy: GenerationWaitPolicy = .standard,
        now: @escaping @Sendable () -> Date = Date.init,
    ) {
        coordinator = GenerationStateCoordinator(
            stateRepository: stateRepository,
            outcomeRepository: outcomeRepository,
            waitPolicy: waitPolicy,
            now: now,
        )
    }

    // MARK: Public

    public func begin(
        githubRepoURL: String,
        requestedAt: Date,
    ) async -> Bool {
        await coordinator.begin(githubRepoURL: githubRepoURL, requestedAt: requestedAt)
    }

    public func attachProjectID(
        _ projectID: String,
        toGithubRepoURL githubRepoURL: String,
    ) async {
        await coordinator.attachProjectID(projectID, toGithubRepoURL: githubRepoURL)
    }

    public func end(githubRepoURL: String) async {
        await coordinator.end(githubRepoURL: githubRepoURL)
    }

    public func end(projectID: String) async {
        await coordinator.end(projectID: projectID)
    }

    public func current() async -> GenerationState {
        await coordinator.current()
    }

    public func states() async -> AsyncStream<GenerationState> {
        await coordinator.states()
    }

    // MARK: Internal

    let coordinator: GenerationStateCoordinator

}
