import DomainIdentifier
import Foundation

public actor ProjectGeneration: ProjectGenerationUseCase {

    // MARK: Lifecycle

    public init(
        repository: any ProjectGenerationRepository,
        pendingGenerations: any PendingGenerationRepository,
        outcomes: any GenerationOutcomeRepository,
        reminderScheduler: any GenerationReminderScheduler,
        signedOutEvents: @escaping @Sendable () async -> AsyncStream<Void>,
        waitPolicy: GenerationWaitPolicy = .standard,
        now: @escaping @Sendable () -> Date = { Date() },
        sleep: @escaping @Sendable (TimeInterval) async throws -> Void = { try await Task.sleep(for: .seconds($0)) },
    ) {
        self.repository = repository
        self.pendingGenerations = pendingGenerations
        self.outcomes = outcomes
        self.reminderScheduler = reminderScheduler
        self.signedOutEvents = signedOutEvents
        self.waitPolicy = waitPolicy
        self.now = now
        self.sleep = sleep
    }

    // MARK: Public

    public func request(_ request: ProjectGenerationRequest) async throws -> ProjectGenerationReceipt {
        guard
            await pendingGenerations.beginGeneration(
                repositoryURL: request.repositoryURL,
                requestedAt: now(),
            )
        else {
            throw ProjectGenerationError.duplicateRequest
        }

        let receipt: ProjectGenerationReceipt
        do {
            receipt = try await repository.register(request)
        } catch {
            await pendingGenerations.releaseGeneration(repositoryURL: request.repositoryURL)
            throw error
        }

        await pendingGenerations.attachProjectID(
            receipt.projectID,
            toRepositoryURL: request.repositoryURL,
        )
        await pendingGenerations.enqueueReminder(projectID: receipt.projectID)
        return receipt
    }

    public func states() async -> AsyncStream<ProjectGenerationState> {
        await startObserving()
        let (stream, continuation) = AsyncStream<ProjectGenerationState>.makeStream()
        let subscriberID = UUID()
        subscribers[subscriberID] = continuation
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeSubscriber(subscriberID) }
        }
        continuation.yield(projectedState())
        return stream
    }

    // MARK: Private

    private let repository: any ProjectGenerationRepository
    private let pendingGenerations: any PendingGenerationRepository
    private let outcomes: any GenerationOutcomeRepository
    private let reminderScheduler: any GenerationReminderScheduler
    private let signedOutEvents: @Sendable () async -> AsyncStream<Void>
    private let waitPolicy: GenerationWaitPolicy
    private let now: @Sendable () -> Date
    private let sleep: @Sendable (TimeInterval) async throws -> Void

    private var generationState = GenerationState()
    private var reminderProjectIDs = Set<ProjectID>()
    private var subscribers = [UUID: AsyncStream<ProjectGenerationState>.Continuation]()
    private var startTask: Task<Void, Never>?
    private var observationTasks = [Task<Void, Never>]()
    private var readyTimerTask: Task<Void, Never>?

    private func startObserving() async {
        if startTask == nil {
            startTask = Task { await self.start() }
        }
        await startTask?.value
    }

    private func start() async {
        await purgeExpiredRecords()
        await absorbPendingReminders()
        await apply(pendingGenerations.pendingState())

        let outcomeStream = await outcomes.outcomes()
        let signedOutStream = await signedOutEvents()
        let changeStream = await pendingGenerations.pendingStateChanges()
        observationTasks = [
            Task { [weak self] in
                for await outcome in outcomeStream {
                    await self?.finish(outcome)
                }
            },
            Task { [weak self] in
                for await _ in signedOutStream {
                    await self?.releaseAll()
                }
            },
            Task { [weak self] in
                for await state in changeStream {
                    await self?.apply(state)
                }
            },
        ]
    }

    private func purgeExpiredRecords() async {
        let current = now()
        for record in await pendingGenerations.pendingState().records
            where waitPolicy.isExpired(
                record,
                now: current,
            )
        {
            if let projectID = record.projectID {
                await pendingGenerations.releaseGeneration(projectID: projectID)
            } else {
                await pendingGenerations.releaseGeneration(repositoryURL: record.repositoryURL)
            }
        }
    }

    private func absorbPendingReminders() async {
        for projectID in await pendingGenerations.drainReminderProjectIDs() {
            reminderProjectIDs.insert(projectID)
        }
    }

    private func finish(_ outcome: GenerationOutcome) async {
        let status: GenerationRecord.Status =
            switch outcome.status {
            case .completed: .completed
            case .failed: .failed
            }
        await pendingGenerations.finishGeneration(
            projectID: outcome.projectID,
            status: status,
            finishedAt: now(),
        )
    }

    private func releaseAll() async {
        reminderProjectIDs.removeAll()
        await pendingGenerations.releaseAll()
        await apply(pendingGenerations.pendingState())
    }

    private func apply(_ state: GenerationState) async {
        generationState = state
        await absorbPendingReminders()
        for record in state.records where record.status != .inProgress {
            await scheduleReminderIfRegistered(for: record)
        }
        emit()
        resetReadyTimer()
    }

    private func scheduleReminderIfRegistered(for record: GenerationRecord) async {
        guard
            let projectID = record.projectID,
            reminderProjectIDs.remove(projectID) != nil,
            await reminderScheduler.isAuthorized()
        else { return }

        switch record.status {
        case .completed:
            await reminderScheduler.schedule(
                GenerationReminder(
                    projectID: projectID,
                    kind: .completed,
                ),
                at: waitPolicy.readyDate(for: record),
            )

        case .failed:
            await reminderScheduler.schedule(
                GenerationReminder(
                    projectID: projectID,
                    kind: .failed,
                ),
                at: now(),
            )

        case .inProgress:
            break
        }
    }

    private func projectedState() -> ProjectGenerationState {
        let current = now()
        let requests = generationState.records.map { record in
            ProjectGenerationRequestState(
                repositoryURL: record.repositoryURL,
                projectID: record.projectID,
                requestedAt: record.requestedAt,
                phase: phase(
                    of: record,
                    now: current,
                ),
            )
        }
        let preparingProjectIDs = requests.reduce(into: Set<ProjectID>()) { projectIDs, request in
            switch request.phase {
            case .inProgress,
                 .preparing:
                if let projectID = request.projectID {
                    projectIDs.insert(projectID)
                }

            case .ready,
                 .failed:
                break
            }
        }
        return ProjectGenerationState(
            requests: requests,
            preparingProjectIDs: preparingProjectIDs,
        )
    }

    private func phase(
        of record: GenerationRecord,
        now: Date,
    ) -> ProjectGenerationPhase {
        let readyAt = waitPolicy.readyDate(for: record)
        switch record.status {
        case .inProgress:
            return .inProgress(readyAt: readyAt)

        case .completed:
            return now < readyAt ? .preparing(readyAt: readyAt) : .ready

        case .failed:
            return .failed
        }
    }

    private func resetReadyTimer() {
        readyTimerTask?.cancel()
        readyTimerTask = nil
        let current = now()
        let earliestReadyAt = generationState.records
            .filter { $0.status == .completed }
            .map { waitPolicy.readyDate(for: $0) }
            .filter { current < $0 }
            .min()
        guard let earliestReadyAt else { return }
        let sleep = sleep
        let delay = earliestReadyAt.timeIntervalSince(current)
        readyTimerTask = Task { [weak self] in
            do {
                try await sleep(delay)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            await self?.readyTimerFired()
        }
    }

    private func readyTimerFired() {
        emit()
        resetReadyTimer()
    }

    private func emit() {
        let state = projectedState()
        for continuation in subscribers.values {
            continuation.yield(state)
        }
    }

    private func removeSubscriber(_ subscriberID: UUID) {
        subscribers.removeValue(forKey: subscriberID)
    }

}
