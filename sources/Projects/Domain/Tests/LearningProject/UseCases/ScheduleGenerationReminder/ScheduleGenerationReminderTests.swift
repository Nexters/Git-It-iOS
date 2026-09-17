import Foundation
import Testing
@testable import DomainLearningProject

// MARK: - ScheduleGenerationReminderTests

@Suite("ScheduleGenerationReminder")
struct ScheduleGenerationReminderTests {

    // MARK: Internal

    @Test
    func `완료 기록은 즉시 발송이 아니라 준비 완료 시각으로 예약된다`() async {
        let requestedAt = Date(timeIntervalSince1970: 1_000)
        let scheduler = SpyGenerationReminderScheduler(isAuthorizedResult: true)
        let schedule = Self.make(scheduler: scheduler)

        await Self.emitFinished(
            projectID: "project-1",
            status: .completed,
            requestedAt: requestedAt,
            schedule: schedule,
            trackGeneration: StubTrackGenerationUseCase(),
        )

        #expect(await scheduler.scheduled == [
            SpyGenerationReminderScheduler.Scheduled(
                identifier: "generation-completed-project-1",
                date: requestedAt.addingTimeInterval(300),
            )
        ])
    }

    @Test
    func `권한이 허용되지 않으면 예약하지 않는다`() async {
        let scheduler = SpyGenerationReminderScheduler(isAuthorizedResult: false)
        let schedule = Self.make(scheduler: scheduler)

        await Self.emitFinished(
            projectID: "project-1",
            status: .completed,
            requestedAt: Date(timeIntervalSince1970: 1_000),
            schedule: schedule,
            trackGeneration: StubTrackGenerationUseCase(),
        )

        #expect(await scheduler.scheduled.isEmpty)
    }

    @Test
    func `등록하지 않은 projectID의 완료 기록은 무시된다`() async {
        let scheduler = SpyGenerationReminderScheduler(isAuthorizedResult: true)
        let schedule = Self.make(scheduler: scheduler)
        let trackGeneration = StubTrackGenerationUseCase()

        await schedule.start(trackGeneration: trackGeneration)
        await trackGeneration.emit(
            Self.state(projectID: "project-1", status: .completed, requestedAt: Date(timeIntervalSince1970: 1_000))
        )
        await trackGeneration.finish()
        await schedule.waitUntilObservationFinished()

        #expect(await scheduler.scheduled.isEmpty)
    }

    @Test
    func `등록된 projectID의 실패 기록은 예약 없이 등록 집합에서 제거만 한다`() async {
        let scheduler = SpyGenerationReminderScheduler(isAuthorizedResult: true)
        let schedule = Self.make(scheduler: scheduler)

        await Self.emitFinished(
            projectID: "project-1",
            status: .failed,
            requestedAt: Date(timeIntervalSince1970: 1_000),
            schedule: schedule,
            trackGeneration: StubTrackGenerationUseCase(),
        )

        #expect(await scheduler.scheduled.isEmpty)
    }

    @Test
    func `같은 완료 기록이 두 스냅샷에 연속으로 담겨도 예약은 1회뿐이다`() async {
        let scheduler = SpyGenerationReminderScheduler(isAuthorizedResult: true)
        let schedule = Self.make(scheduler: scheduler)
        let trackGeneration = StubTrackGenerationUseCase()
        let finished = Self.state(
            projectID: "project-1",
            status: .completed,
            requestedAt: Date(timeIntervalSince1970: 1_000),
        )

        await schedule.register(projectID: "project-1")
        await schedule.start(trackGeneration: trackGeneration)
        await trackGeneration.emit(finished)
        await trackGeneration.emit(finished)
        await trackGeneration.finish()
        await schedule.waitUntilObservationFinished()

        #expect(await scheduler.scheduled.map(\.identifier) == ["generation-completed-project-1"])
    }

    @Test
    func `대기 중이던 리마인드를 흡수해 등록 대상으로 삼는다`() async {
        let scheduler = SpyGenerationReminderScheduler(isAuthorizedResult: true)
        let schedule = ScheduleGenerationReminder(
            scheduler: scheduler,
            pendingGenerations: StubPendingGenerationRepository(reminderProjectIDs: ["project-1"]),
            waitPolicy: GenerationWaitPolicy(minimumWait: 300, retentionLimit: 3_600),
        )
        let trackGeneration = StubTrackGenerationUseCase()

        await schedule.start(trackGeneration: trackGeneration)
        await trackGeneration.emit(
            Self.state(projectID: "project-1", status: .completed, requestedAt: Date(timeIntervalSince1970: 1_000))
        )
        await trackGeneration.finish()
        await schedule.waitUntilObservationFinished()

        #expect(await scheduler.scheduled.count == 1)
    }

    // MARK: Private

    private static func make(scheduler: SpyGenerationReminderScheduler) -> ScheduleGenerationReminder {
        ScheduleGenerationReminder(
            scheduler: scheduler,
            waitPolicy: GenerationWaitPolicy(minimumWait: 300, retentionLimit: 3_600),
        )
    }

    private static func state(
        projectID: String,
        status: GenerationRecord.Status,
        requestedAt: Date,
    ) -> GenerationState {
        GenerationState(records: [
            GenerationRecord(
                githubRepoURL: "https://github.com/owner/\(projectID)",
                projectID: projectID,
                requestedAt: requestedAt,
                status: status,
                finishedAt: requestedAt,
            )
        ])
    }

    private static func emitFinished(
        projectID: String,
        status: GenerationRecord.Status,
        requestedAt: Date,
        schedule: ScheduleGenerationReminder,
        trackGeneration: StubTrackGenerationUseCase,
    ) async {
        await schedule.register(projectID: projectID)
        await schedule.start(trackGeneration: trackGeneration)
        await trackGeneration.emit(Self.state(projectID: projectID, status: status, requestedAt: requestedAt))
        await trackGeneration.finish()
        await schedule.waitUntilObservationFinished()
    }

}

// MARK: - SpyGenerationReminderScheduler

private actor SpyGenerationReminderScheduler: GenerationReminderScheduler {

    // MARK: Lifecycle

    init(isAuthorizedResult: Bool) {
        self.isAuthorizedResult = isAuthorizedResult
    }

    // MARK: Internal

    struct Scheduled: Equatable, Sendable {
        let identifier: String
        let date: Date
    }

    private(set) var scheduled = [Scheduled]()

    func isAuthorized() async -> Bool {
        isAuthorizedResult
    }

    func schedule(
        identifier: String,
        at date: Date,
    ) async {
        scheduled.append(Scheduled(identifier: identifier, date: date))
    }

    // MARK: Private

    private let isAuthorizedResult: Bool

}

// MARK: - StubTrackGenerationUseCase

private actor StubTrackGenerationUseCase: TrackGenerationUseCase {

    // MARK: Internal

    func begin(
        githubRepoURL _: String,
        requestedAt _: Date,
    ) async -> Bool {
        true
    }

    func attachProjectID(
        _: String,
        toGithubRepoURL _: String,
    ) async { }

    func end(githubRepoURL _: String) async { }
    func end(projectID _: String) async { }
    func current() async -> GenerationState {
        GenerationState()
    }

    func states() async -> AsyncStream<GenerationState> {
        let (stream, continuation) = AsyncStream<GenerationState>.makeStream()
        self.continuation = continuation
        return stream
    }

    func emit(_ state: GenerationState) {
        continuation?.yield(state)
    }

    func finish() {
        continuation?.finish()
    }

    // MARK: Private

    private var continuation: AsyncStream<GenerationState>.Continuation?

}
