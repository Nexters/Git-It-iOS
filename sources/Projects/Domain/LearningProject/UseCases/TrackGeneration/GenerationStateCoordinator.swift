import Foundation

actor GenerationStateCoordinator {

    // MARK: Lifecycle

    init(
        stateRepository: any GenerationStateRepository,
        outcomeRepository: any GenerationOutcomeRepository,
        waitPolicy: GenerationWaitPolicy,
        now: @escaping @Sendable () -> Date,
    ) {
        self.stateRepository = stateRepository
        self.outcomeRepository = outcomeRepository
        self.waitPolicy = waitPolicy
        self.now = now
    }

    // MARK: Internal

    var observerCount: Int {
        observers.count
    }

    func current() async -> GenerationState {
        await ensureStarted()
        return await purged()
    }

    func states() async -> AsyncStream<GenerationState> {
        await ensureStarted()
        let snapshot = await purged()
        let observerID = UUID()
        return AsyncStream { continuation in
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeObserver(observerID) }
            }
            continuation.yield(snapshot)
            Task { await self.addObserver(observerID, continuation) }
        }
    }

    func begin(
        githubRepoURL: String,
        requestedAt: Date,
    ) async -> Bool {
        await ensureStarted()
        guard let next = await purged().beginning(githubRepoURL: githubRepoURL, requestedAt: requestedAt)
        else { return false }
        await update(next)
        return true
    }

    func attachProjectID(
        _ projectID: String,
        toGithubRepoURL githubRepoURL: String,
    ) async {
        await ensureStarted()
        await update(await purged().attachingProjectID(projectID, toGithubRepoURL: githubRepoURL))
    }

    func end(githubRepoURL: String) async {
        await ensureStarted()
        await update(await purged().removing(githubRepoURL: githubRepoURL))
    }

    func end(projectID: String) async {
        await ensureStarted()
        await update(await purged().removing(projectID: projectID))
    }

    // MARK: Private

    private let stateRepository: any GenerationStateRepository
    private let outcomeRepository: any GenerationOutcomeRepository
    private let waitPolicy: GenerationWaitPolicy
    private let now: @Sendable () -> Date

    private var state = GenerationState()
    private var observers = [UUID: AsyncStream<GenerationState>.Continuation]()
    private var startTask: Task<Void, Never>?
    private var observationTask: Task<Void, Never>?

    private func ensureStarted() async {
        if startTask == nil {
            startTask = Task { [self] in await start() }
        }
        await startTask?.value
    }

    private func start() async {
        state = await stateRepository.currentState()
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
        await update(
            await purged().finishing(projectID: outcome.projectID, status: status, at: now())
        )
    }

    private func purged() async -> GenerationState {
        state.purgingExpired(now: now(), retentionLimit: waitPolicy.retentionLimit)
    }

    private func update(_ next: GenerationState) async {
        state = next
        await stateRepository.record(next)
        for continuation in observers.values {
            continuation.yield(next)
        }
    }

    private func addObserver(
        _ observerID: UUID,
        _ continuation: AsyncStream<GenerationState>.Continuation,
    ) {
        observers[observerID] = continuation
    }

    private func removeObserver(_ observerID: UUID) {
        observers.removeValue(forKey: observerID)
    }

}
