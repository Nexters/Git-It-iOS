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
    ) {
        self.repository = repository
        self.pendingGenerations = pendingGenerations
        self.outcomes = outcomes
        self.reminderScheduler = reminderScheduler
        self.signedOutEvents = signedOutEvents
        self.waitPolicy = waitPolicy
        self.now = now
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

    private var generationState = GenerationState()
    private var reminderProjectIDs = Set<ProjectID>()
    private var subscribers = [UUID: AsyncStream<ProjectGenerationState>.Continuation]()
    private var startTask: Task<Void, Never>?
    private var observationTasks = [Task<Void, Never>]()

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
                at: now(),
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
        ProjectGenerationState(
            requests: generationState.records.map { record in
                ProjectGenerationRequestState(
                    repositoryURL: record.repositoryURL,
                    projectID: record.projectID,
                    requestedAt: record.requestedAt,
                    phase: phase(of: record),
                )
            }
        )
    }

    private func phase(of record: GenerationRecord) -> ProjectGenerationPhase {
        switch record.status {
        case .inProgress: .inProgress
        case .completed: .ready
        case .failed: .failed
        }
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
