import Foundation
import Testing

@testable import DomainProjectGeneration

@Suite("ProjectGeneration")
struct ProjectGenerationTests {

    // MARK: Internal

    @Test
    func `같은 저장소로 진행 중인 생성이 있으면 duplicateRequest를 던진다`() async throws {
        let fixture = Fixture()

        _ = try await fixture.generation.request(Self.request)

        await #expect(throws: ProjectGenerationError.duplicateRequest) {
            try await fixture.generation.request(Self.request)
        }
        #expect(await fixture.repository.requests.count == 1)
    }

    @Test
    func `등록에 실패하면 생성 기록을 해제하고 오류를 전달한다`() async {
        let fixture = Fixture(repository: StubProjectGenerationRepository(error: .temporarilyUnavailable))

        await #expect(throws: ProjectGenerationError.temporarilyUnavailable) {
            try await fixture.generation.request(Self.request)
        }
        #expect(await fixture.pendingGenerations.state.records.isEmpty)
    }

    @Test
    func `요청만 호출하면 결과 관찰을 시작하지 않고 알림 대상을 대기열에 남긴다`() async throws {
        let fixture = Fixture()

        let receipt = try await fixture.generation.request(Self.request)
        fixture.outcomes.emit(GenerationOutcome(
            projectID: receipt.projectID,
            status: .completed,
        ))
        for _ in 0 ..< 50 {
            await Task.yield()
        }

        #expect(receipt == ProjectGenerationReceipt(
            projectID: "p1",
            quizLevel: .l2,
        ))
        #expect(await fixture.pendingGenerations.subscriberCount == 0)
        #expect(await fixture.pendingGenerations.finishedProjectIDs.isEmpty)
        #expect(await fixture.pendingGenerations.reminderProjectIDs == ["p1"])
    }

    @Test
    func `생성 중과 준비 중인 프로젝트를 배너 대상으로 보고 대기 시간이 지나면 ready를 방출한다`() async throws {
        let fixture = Fixture()
        _ = try await fixture.generation.request(Self.request)
        var states = await fixture.generation.states().makeAsyncIterator()

        let inProgress = await Self.next(&states) { _ in true }
        #expect(inProgress?.requests.map(\.phase) == [.inProgress(readyAt: Self.readyAt)])
        #expect(inProgress?.preparingProjectIDs == ["p1"])

        fixture.sleeper.advance(by: 10)
        fixture.outcomes.emit(GenerationOutcome(
            projectID: "p1",
            status: .completed,
        ))
        let preparing = await Self.next(&states) { $0.requests.first?.phase == .preparing(readyAt: Self.readyAt) }
        #expect(preparing?.preparingProjectIDs == ["p1"])

        await Self.settle { fixture.sleeper.sleeperCount > 0 }
        fixture.sleeper.advance(by: 290)
        let ready = await Self.next(&states) { $0.requests.first?.phase == .ready }
        #expect(ready?.preparingProjectIDs.isEmpty == true)
    }

    @Test
    func `생성이 완료되면 준비 완료 시각에 완료 알림을 예약한다`() async throws {
        let fixture = Fixture()
        _ = try await fixture.generation.request(Self.request)
        var states = await fixture.generation.states().makeAsyncIterator()
        _ = await states.next()

        fixture.outcomes.emit(GenerationOutcome(
            projectID: "p1",
            status: .completed,
        ))
        _ = await Self.next(&states) { $0.requests.first?.phase == .preparing(readyAt: Self.readyAt) }

        #expect(await fixture.scheduler.scheduledReminders == [
            .init(
                reminder: GenerationReminder(
                    projectID: "p1",
                    kind: .completed,
                ),
                date: Self.readyAt,
            )
        ])
    }

    @Test
    func `생성이 실패하면 즉시 failed를 방출하고 실패 알림을 보낸다`() async throws {
        let fixture = Fixture()
        _ = try await fixture.generation.request(Self.request)
        var states = await fixture.generation.states().makeAsyncIterator()
        _ = await states.next()

        fixture.outcomes.emit(GenerationOutcome(
            projectID: "p1",
            status: .failed,
        ))
        let failed = await Self.next(&states) { $0.requests.first?.phase == .failed }

        #expect(failed?.preparingProjectIDs.isEmpty == true)
        #expect(await fixture.scheduler.scheduledReminders == [
            .init(
                reminder: GenerationReminder(
                    projectID: "p1",
                    kind: .failed,
                ),
                date: Self.requestedAt,
            )
        ])
    }

    @Test
    func `알림 권한이 없으면 생성 결과 알림을 예약하지 않는다`() async throws {
        let fixture = Fixture(scheduler: SpyGenerationReminderScheduler(isAuthorized: false))
        _ = try await fixture.generation.request(Self.request)
        var states = await fixture.generation.states().makeAsyncIterator()
        _ = await states.next()

        fixture.outcomes.emit(GenerationOutcome(
            projectID: "p1",
            status: .failed,
        ))
        _ = await Self.next(&states) { $0.requests.first?.phase == .failed }

        #expect(await fixture.scheduler.scheduledReminders.isEmpty)
    }

    @Test
    func `관찰을 시작하면 보관 기한이 지난 기록을 정리한다`() async {
        let expired = GenerationRecord(
            repositoryURL: Self.request.repositoryURL,
            projectID: "p0",
            requestedAt: Self.requestedAt.addingTimeInterval(-3_601),
        )
        let fixture = Fixture(pendingGenerations: InMemoryPendingGenerationRepository(state: GenerationState(records: [expired])))

        var states = await fixture.generation.states().makeAsyncIterator()
        let state = await states.next()

        #expect(state?.requests.isEmpty == true)
        #expect(await fixture.pendingGenerations.state.records.isEmpty)
    }

    @Test
    func `로그아웃하면 생성 기록을 모두 해제하고 빈 상태를 방출한다`() async throws {
        let fixture = Fixture()
        _ = try await fixture.generation.request(Self.request)
        var states = await fixture.generation.states().makeAsyncIterator()
        _ = await states.next()

        fixture.signedOutContinuation.yield(())
        let state = await Self.next(&states) { $0.requests.isEmpty }

        #expect(state?.preparingProjectIDs.isEmpty == true)
        #expect(await fixture.pendingGenerations.state.records.isEmpty)
    }

    // MARK: Private

    private struct Fixture {

        // MARK: Lifecycle

        init(
            repository: StubProjectGenerationRepository = StubProjectGenerationRepository(),
            pendingGenerations: InMemoryPendingGenerationRepository = InMemoryPendingGenerationRepository(),
            scheduler: SpyGenerationReminderScheduler = SpyGenerationReminderScheduler(),
        ) {
            let outcomes = StubGenerationOutcomeRepository()
            let sleeper = ManualSleeper(now: ProjectGenerationTests.requestedAt)
            let (signedOut, signedOutContinuation) = AsyncStream<Void>.makeStream()
            self.repository = repository
            self.pendingGenerations = pendingGenerations
            self.scheduler = scheduler
            self.outcomes = outcomes
            self.sleeper = sleeper
            self.signedOutContinuation = signedOutContinuation
            generation = ProjectGeneration(
                repository: repository,
                pendingGenerations: pendingGenerations,
                outcomes: outcomes,
                reminderScheduler: scheduler,
                signedOutEvents: { signedOut },
                now: { sleeper.now },
                sleep: { try await sleeper.sleep($0) },
            )
        }

        // MARK: Internal

        let repository: StubProjectGenerationRepository
        let pendingGenerations: InMemoryPendingGenerationRepository
        let scheduler: SpyGenerationReminderScheduler
        let outcomes: StubGenerationOutcomeRepository
        let sleeper: ManualSleeper
        let signedOutContinuation: AsyncStream<Void>.Continuation
        let generation: ProjectGeneration

    }

    private static let request = ProjectGenerationRequest(
        repositoryURL: "https://github.com/owner/repo",
        quizLevel: .l2,
    )
    private static let requestedAt = Date(timeIntervalSince1970: 10_000)
    private static let readyAt = requestedAt.addingTimeInterval(300)

    private static func next(
        _ iterator: inout AsyncStream<ProjectGenerationState>.Iterator,
        where predicate: (ProjectGenerationState) -> Bool,
    ) async -> ProjectGenerationState? {
        while let state = await iterator.next() {
            if predicate(state) {
                return state
            }
        }
        return nil
    }

    private static func settle(until condition: @Sendable () async -> Bool) async {
        for _ in 0 ..< 200 {
            guard await !condition() else { return }
            await Task.yield()
        }
    }

}
