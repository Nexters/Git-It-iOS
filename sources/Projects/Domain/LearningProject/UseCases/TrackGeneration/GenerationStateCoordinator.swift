import Foundation

actor GenerationStateCoordinator {

    // MARK: Lifecycle

    init(
        pendingGenerations: any PendingGenerationRepository,
        outcomeRepository: any GenerationOutcomeRepository,
        now: @escaping @Sendable () -> Date,
    ) {
        self.pendingGenerations = pendingGenerations
        self.outcomeRepository = outcomeRepository
        self.now = now
    }

    // MARK: Internal

    func ensureStarted() async {
        if startTask == nil {
            startTask = Task { [self] in await start() }
        }
        await startTask?.value
    }

    // MARK: Private

    private let pendingGenerations: any PendingGenerationRepository
    private let outcomeRepository: any GenerationOutcomeRepository
    private let now: @Sendable () -> Date

    private var startTask: Task<Void, Never>?
    private var observationTask: Task<Void, Never>?

    private func start() async {
        let outcomes = await outcomeRepository.outcomes()
        observationTask = Task { [weak self] in
            for await outcome in outcomes {
                await self?.apply(outcome)
            }
        }
    }

    private func apply(_ outcome: GenerationOutcome) async {
        let status: GenerationRecord.Status =
            switch outcome.status {
            case .completed: .completed
            case .failed: .failed
            }
        await pendingGenerations.finishGeneration(projectID: outcome.projectID, status: status, finishedAt: now())
    }

}
