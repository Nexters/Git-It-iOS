import Foundation

// MARK: - ScheduleGenerationReminder

public actor ScheduleGenerationReminder: ScheduleGenerationReminderUseCase {

    // MARK: Lifecycle

    public init(
        scheduler: any GenerationReminderScheduler,
        pendingReminders: (any PendingGenerationReminders)? = nil,
        waitPolicy: GenerationWaitPolicy = .standard,
    ) {
        self.scheduler = scheduler
        self.pendingReminders = pendingReminders
        self.waitPolicy = waitPolicy
    }

    // MARK: Public

    public func register(projectID: String) async {
        registeredProjectIDs.insert(projectID)
    }

    public func absorbPendingReminders() async {
        guard let pendingReminders else { return }
        for projectID in await pendingReminders.drainProjectIDs() {
            await register(projectID: projectID)
        }
    }

    public func start(trackGeneration: any TrackGenerationUseCase) async {
        await absorbPendingReminders()
        let states = await trackGeneration.states()
        observationTask = Task {
            for await state in states {
                await self.handle(state)
            }
        }
    }

    public func waitUntilObservationFinished() async {
        await observationTask?.value
    }

    // MARK: Private

    private let scheduler: any GenerationReminderScheduler
    private let pendingReminders: (any PendingGenerationReminders)?
    private let waitPolicy: GenerationWaitPolicy
    private var registeredProjectIDs = Set<String>()
    private var observationTask: Task<Void, Never>?

    private static func notificationIdentifier(projectID: String) -> String {
        "generation-completed-\(projectID)"
    }

    private func handle(_ state: GenerationState) async {
        for record in state.records where record.status != .inProgress {
            await handle(record)
        }
    }

    private func handle(_ record: GenerationRecord) async {
        guard let projectID = record.projectID else { return }
        guard registeredProjectIDs.remove(projectID) != nil else { return }
        guard record.status == .completed else { return }
        guard await scheduler.isAuthorized() else { return }

        await scheduler.schedule(
            identifier: Self.notificationIdentifier(projectID: projectID),
            at: waitPolicy.readyDate(for: record),
        )
    }

}
