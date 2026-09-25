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
        fixture.outcomes.emit(Self.outcome(
            receipt.projectID,
            .completed,
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
    func `생성 중인 요청은 결과가 도착하면 바로 ready를 방출한다`() async throws {
        let fixture = Fixture()
        _ = try await fixture.generation.request(Self.request)
        var states = await fixture.generation.states().makeAsyncIterator()

        let inProgress = await Self.next(&states) { _ in true }
        #expect(inProgress?.requests.map(\.phase) == [.inProgress])

        fixture.sleeper.advance(by: 10)
        fixture.outcomes.emit(Self.outcome(
            "p1",
            .completed,
            arrivedAt: fixture.sleeper.now,
        ))
        let ready = await Self.next(&states) { $0.requests.first?.phase == .ready }

        #expect(ready?.requests.first?.projectID == "p1")
    }

    @Test
    func `생성이 완료되면 즉시 완료 알림을 예약한다`() async throws {
        let fixture = Fixture()
        _ = try await fixture.generation.request(Self.request)
        var states = await fixture.generation.states().makeAsyncIterator()
        _ = await states.next()

        fixture.outcomes.emit(Self.outcome(
            "p1",
            .completed,
            arrivedAt: fixture.sleeper.now,
        ))
        _ = await Self.next(&states) { $0.requests.first?.phase == .ready }

        #expect(await fixture.scheduler.scheduledReminders == [
            .init(
                reminder: GenerationReminder(
                    projectID: "p1",
                    kind: .completed,
                ),
                date: Self.requestedAt,
            )
        ])
    }

    @Test
    func `생성이 실패하면 즉시 failed를 방출하고 실패 알림을 보낸다`() async throws {
        let fixture = Fixture()
        _ = try await fixture.generation.request(Self.request)
        var states = await fixture.generation.states().makeAsyncIterator()
        _ = await states.next()

        fixture.outcomes.emit(Self.outcome(
            "p1",
            .failed,
        ))
        _ = await Self.next(&states) { $0.requests.first?.phase == .failed }

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

        fixture.outcomes.emit(Self.outcome(
            "p1",
            .failed,
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
        let fixture = Fixture(state: GenerationState(records: [expired]))

        var states = await fixture.generation.states().makeAsyncIterator()
        let state = await states.next()

        #expect(state?.requests.isEmpty == true)
    }

    @Test
    func `로그아웃하면 생성 기록을 모두 해제하고 빈 상태를 방출한다`() async throws {
        let fixture = Fixture()
        _ = try await fixture.generation.request(Self.request)
        var states = await fixture.generation.states().makeAsyncIterator()
        _ = await states.next()

        fixture.signedOutContinuation.yield(())
        _ = await Self.next(&states) { $0.requests.isEmpty }

        #expect(await fixture.pendingGenerations.state.records.isEmpty)
    }

    @Test
    func `결과가 반영되면 기록의 완료 시각은 결과 도착 시각이다`() async throws {
        let fixture = Fixture()
        _ = try await fixture.generation.request(Self.request)
        var states = await fixture.generation.states().makeAsyncIterator()
        _ = await states.next()
        let arrivedAt = Self.requestedAt.addingTimeInterval(5)

        fixture.outcomes.emit(Self.outcome(
            "p1",
            .completed,
            arrivedAt: arrivedAt,
        ))
        _ = await Self.next(&states) { $0.requests.first?.phase == .ready }

        #expect(await fixture.pendingGenerations.state.records.first?.finishedAt == arrivedAt)
    }

    @Test
    func `기록에 없는 프로젝트의 결과를 보존했다가 식별자가 연결되면 반영한다`() async {
        let fixture = Fixture(state: Self.unattachedState(repositoryURLs: [Self.request.repositoryURL]))
        var states = await fixture.generation.states().makeAsyncIterator()
        _ = await states.next()

        fixture.outcomes.emit(Self.outcome(
            "p1",
            .completed,
        ))
        await Self.settle { await fixture.pendingGenerations.finishedProjectIDs == ["p1"] }
        await fixture.pendingGenerations.attachProjectID(
            "p1",
            toRepositoryURL: Self.request.repositoryURL,
        )
        let ready = await Self.next(&states) { $0.requests.first?.phase == .ready }

        #expect(ready?.requests.first?.projectID == "p1")
    }

    @Test
    func `같은 결과가 두 번 도착해도 기록 전이와 알림 예약은 한 번이다`() async throws {
        let fixture = Fixture()
        _ = try await fixture.generation.request(Self.request)
        var states = await fixture.generation.states().makeAsyncIterator()
        _ = await states.next()

        fixture.outcomes.emit(Self.outcome(
            "p1",
            .completed,
        ))
        fixture.outcomes.emit(Self.outcome(
            "p1",
            .completed,
            arrivedAt: Self.requestedAt.addingTimeInterval(1),
        ))
        _ = await Self.next(&states) { $0.requests.first?.phase == .ready }
        await Self.settle { await fixture.pendingGenerations.finishedProjectIDs.count == 2 }

        #expect(await fixture.pendingGenerations.state.records.first?.finishedAt == Self.requestedAt)
        #expect(await fixture.scheduler.scheduledReminders.count == 1)
    }

    @Test
    func `보존 결과가 16개를 넘으면 가장 오래된 결과부터 버린다`() async {
        let repositoryURLs = (0 ... 16).map { "https://github.com/owner/repo\($0)" }
        let fixture = Fixture(state: Self.unattachedState(repositoryURLs: repositoryURLs))
        var states = await fixture.generation.states().makeAsyncIterator()
        _ = await states.next()

        for index in 0 ... 16 {
            fixture.outcomes.emit(Self.outcome(
                "p\(index)",
                .completed,
            ))
        }
        await Self.settle { await fixture.pendingGenerations.finishedProjectIDs.count == 17 }
        await fixture.pendingGenerations.attachProjectID(
            "p0",
            toRepositoryURL: repositoryURLs[0],
        )
        await fixture.pendingGenerations.attachProjectID(
            "p16",
            toRepositoryURL: repositoryURLs[16],
        )
        let state = await Self.next(&states) { state in
            state.requests.contains { $0.projectID == "p16" && $0.phase == .ready }
        }

        #expect(state?.requests.first { $0.projectID == "p0" }?.phase == .inProgress)
    }

    @Test
    func `보관 기한이 지난 보존 결과는 반영하지 않는다`() async {
        let fixture = Fixture(state: Self.unattachedState(repositoryURLs: [Self.request.repositoryURL]))
        var states = await fixture.generation.states().makeAsyncIterator()
        _ = await states.next()

        fixture.outcomes.emit(Self.outcome(
            "p1",
            .completed,
            arrivedAt: Self.requestedAt.addingTimeInterval(-3_000),
        ))
        await Self.settle { await fixture.pendingGenerations.finishedProjectIDs == ["p1"] }
        fixture.sleeper.advance(by: 700)
        await fixture.pendingGenerations.attachProjectID(
            "p1",
            toRepositoryURL: Self.request.repositoryURL,
        )
        _ = await Self.next(&states) { $0.requests.first?.projectID == "p1" }
        await Self.settle { await fixture.pendingGenerations.finishedProjectIDs.count > 1 }

        #expect(await fixture.pendingGenerations.state.records.first?.status == .inProgress)
    }

    @Test
    func `로그아웃하면 보존 결과를 버린다`() async throws {
        let fixture = Fixture(state: Self.unattachedState(repositoryURLs: ["https://github.com/owner/other"]))
        var states = await fixture.generation.states().makeAsyncIterator()
        _ = await states.next()

        fixture.outcomes.emit(Self.outcome(
            "p1",
            .completed,
        ))
        await Self.settle { await fixture.pendingGenerations.finishedProjectIDs == ["p1"] }
        fixture.signedOutContinuation.yield(())
        _ = await Self.next(&states) { $0.requests.isEmpty }
        _ = try await fixture.generation.request(Self.request)
        _ = await Self.next(&states) { $0.requests.first?.projectID == "p1" }
        await Self.settle { await fixture.pendingGenerations.finishedProjectIDs.count > 1 }

        #expect(await fixture.pendingGenerations.state.records.first?.status == .inProgress)
    }

    @Test
    func `결과 없이 보관 기한에 도달하면 재실행 없이 진행 중 기록이 빠진 상태를 방출한다`() async throws {
        let fixture = Fixture()
        _ = try await fixture.generation.request(Self.request)
        var states = await fixture.generation.states().makeAsyncIterator()
        _ = await states.next()

        await Self.advance(
            fixture.sleeper,
            by: 3_601,
        )
        let state = await Self.next(&states) { $0.requests.isEmpty }

        #expect(state?.requests.isEmpty == true)
    }

    @Test
    func `완료 기록의 보관 기한에 도달하면 기록을 정리한다`() async throws {
        let fixture = Fixture()
        _ = try await fixture.generation.request(Self.request)
        var states = await fixture.generation.states().makeAsyncIterator()
        _ = await states.next()
        fixture.outcomes.emit(Self.outcome(
            "p1",
            .completed,
        ))
        _ = await Self.next(&states) { $0.requests.first?.phase == .ready }

        await Self.advance(
            fixture.sleeper,
            by: 3_601,
        )
        let state = await Self.next(&states) { $0.requests.isEmpty }

        #expect(state?.requests.isEmpty == true)
    }

    @Test
    func `결과 도착 후 5분 안이고 권한이 있으면 알림을 한 번 예약한다`() async throws {
        let fixture = Fixture()
        _ = try await fixture.generation.request(Self.request)
        var states = await fixture.generation.states().makeAsyncIterator()
        _ = await states.next()
        fixture.sleeper.advance(by: 100)

        fixture.outcomes.emit(Self.outcome(
            "p1",
            .completed,
        ))
        _ = await Self.next(&states) { $0.requests.first?.phase == .ready }
        await Self.settle { await !fixture.scheduler.scheduledReminders.isEmpty }

        #expect(await fixture.scheduler.scheduledReminders.count == 1)
    }

    @Test
    func `결과 도착 후 5분이 지나면 권한이 있어도 알림을 예약하지 않는다`() async throws {
        let fixture = Fixture()
        _ = try await fixture.generation.request(Self.request)
        var states = await fixture.generation.states().makeAsyncIterator()
        _ = await states.next()
        fixture.sleeper.advance(by: 400)

        fixture.outcomes.emit(Self.outcome(
            "p1",
            .completed,
        ))
        _ = await Self.next(&states) { $0.requests.first?.phase == .ready }

        #expect(await fixture.scheduler.scheduledReminders.isEmpty)
    }

    @Test
    func `권한이 없어 버린 리마인드 대상은 나중에 권한이 생겨도 예약하지 않는다`() async throws {
        let fixture = Fixture(scheduler: SpyGenerationReminderScheduler(isAuthorized: false))
        _ = try await fixture.generation.request(Self.request)
        var states = await fixture.generation.states().makeAsyncIterator()
        _ = await states.next()
        fixture.outcomes.emit(Self.outcome(
            "p1",
            .completed,
        ))
        _ = await Self.next(&states) { $0.requests.first?.phase == .ready }

        await fixture.scheduler.setAuthorized(true)
        await Self.advance(
            fixture.sleeper,
            by: 300,
        )
        _ = await Self.next(&states) { $0.requests.first?.phase == .ready }

        #expect(await fixture.scheduler.scheduledReminders.isEmpty)
    }

    @Test
    func `로그아웃하면 모든 기록의 프로젝트 알림 예약을 취소한다`() async throws {
        let fixture = Fixture()
        _ = try await fixture.generation.request(Self.request)
        var states = await fixture.generation.states().makeAsyncIterator()
        _ = await states.next()

        fixture.signedOutContinuation.yield(())
        _ = await Self.next(&states) { $0.requests.isEmpty }

        #expect(await fixture.scheduler.cancelledProjectIDs.contains("p1"))
    }

    @Test
    func `보관 기한이 지나 상태에서 사라진 기록의 프로젝트 알림 예약을 취소한다`() async throws {
        let fixture = Fixture()
        _ = try await fixture.generation.request(Self.request)
        var states = await fixture.generation.states().makeAsyncIterator()
        _ = await states.next()
        fixture.outcomes.emit(Self.outcome(
            "p1",
            .completed,
        ))
        _ = await Self.next(&states) { $0.requests.first?.phase == .ready }

        await Self.advance(
            fixture.sleeper,
            by: 3_601,
        )
        _ = await Self.next(&states) { $0.requests.isEmpty }

        #expect(await fixture.scheduler.cancelledProjectIDs == ["p1"])
    }

    @Test
    func `앱 밖에서 저장소 기록이 사라지면 다음 상태 적용 때 그 프로젝트 알림 예약을 취소한다`() async throws {
        let fixture = Fixture()
        _ = try await fixture.generation.request(Self.request)
        var states = await fixture.generation.states().makeAsyncIterator()
        _ = await states.next()

        await fixture.pendingGenerations.replaceStateSilently(GenerationState())
        await Self.advance(
            fixture.sleeper,
            by: 1,
        )
        _ = await Self.next(&states) { $0.requests.isEmpty }

        #expect(await fixture.scheduler.cancelledProjectIDs == ["p1"])
    }

    @Test
    func `저장소가 앱 밖에서 바뀐 뒤 동기화하면 그 기록을 상태에 반영한다`() async throws {
        let fixture = Fixture()
        _ = try await fixture.generation.request(Self.request)
        var states = await fixture.generation.states().makeAsyncIterator()
        _ = await states.next()
        let finished = GenerationRecord(
            repositoryURL: Self.request.repositoryURL,
            projectID: "p1",
            requestedAt: Self.requestedAt,
            status: .failed,
            finishedAt: Self.requestedAt,
        )

        await fixture.pendingGenerations.replaceStateSilently(GenerationState(records: [finished]))
        await fixture.generation.synchronize()
        let state = await Self.next(&states) { $0.requests.first?.phase == .failed }

        #expect(state?.requests.first?.projectID == "p1")
    }

    @Test
    func `동기화하면 보존 결과 반영을 다시 시도한다`() async {
        let fixture = Fixture(state: Self.unattachedState(repositoryURLs: [Self.request.repositoryURL]))
        var states = await fixture.generation.states().makeAsyncIterator()
        _ = await states.next()
        fixture.outcomes.emit(Self.outcome(
            "p1",
            .completed,
        ))
        await Self.settle { await fixture.pendingGenerations.finishedProjectIDs == ["p1"] }
        let attached = GenerationState(records: [GenerationRecord(
            repositoryURL: Self.request.repositoryURL,
            projectID: "p1",
            requestedAt: Self.requestedAt,
        )])

        await fixture.pendingGenerations.replaceStateSilently(attached)
        await fixture.generation.synchronize()
        let state = await Self.next(&states) { $0.requests.first?.phase == .ready }

        #expect(state?.requests.first?.projectID == "p1")
    }

    @Test
    func `동기화하면 보관 기한이 지난 기록을 정리하고 알림 예약을 취소한다`() async throws {
        let fixture = Fixture()
        _ = try await fixture.generation.request(Self.request)
        var states = await fixture.generation.states().makeAsyncIterator()
        _ = await states.next()

        fixture.sleeper.advance(by: 3_601)
        await fixture.generation.synchronize()
        _ = await Self.next(&states) { $0.requests.isEmpty }

        #expect(await fixture.scheduler.cancelledProjectIDs.contains("p1"))
    }

    @Test
    func `프로젝트를 해제하면 기록과 리마인드 대상을 지우고 알림 예약을 취소한다`() async throws {
        let fixture = Fixture()
        _ = try await fixture.generation.request(Self.request)
        var states = await fixture.generation.states().makeAsyncIterator()
        _ = await states.next()

        await fixture.generation.release("p1")
        _ = await Self.next(&states) { $0.requests.isEmpty }
        fixture.outcomes.emit(Self.outcome(
            "p1",
            .completed,
        ))
        await Self.settle { await fixture.pendingGenerations.finishedProjectIDs == ["p1"] }

        #expect(await fixture.pendingGenerations.state.records.isEmpty)
        #expect(await fixture.scheduler.cancelledProjectIDs.contains("p1"))
        #expect(await fixture.scheduler.scheduledReminders.isEmpty)
    }

    @Test
    func `기록이 없는 프로젝트를 해제해도 오류 없이 끝난다`() async {
        let fixture = Fixture()

        await fixture.generation.release("p-unknown")

        #expect(await fixture.pendingGenerations.state.records.isEmpty)
        #expect(await fixture.scheduler.cancelledProjectIDs == ["p-unknown"])
    }

    // MARK: Private

    private struct Fixture {

        // MARK: Lifecycle

        init(
            repository: StubProjectGenerationRepository = StubProjectGenerationRepository(),
            state: GenerationState = GenerationState(),
            scheduler: SpyGenerationReminderScheduler = SpyGenerationReminderScheduler(),
        ) {
            let outcomes = StubGenerationOutcomeRepository()
            let sleeper = ManualSleeper(now: ProjectGenerationTests.requestedAt)
            let pendingGenerations = InMemoryPendingGenerationRepository(
                state: state,
                now: { sleeper.now },
            )
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

    private static func outcome(
        _ projectID: String,
        _ status: GenerationOutcome.Status,
        arrivedAt: Date = requestedAt,
    ) -> GenerationOutcome {
        GenerationOutcome(
            projectID: projectID,
            status: status,
            arrivedAt: arrivedAt,
        )
    }

    private static func unattachedState(repositoryURLs: [String]) -> GenerationState {
        GenerationState(records: repositoryURLs.map { repositoryURL in
            GenerationRecord(
                repositoryURL: repositoryURL,
                requestedAt: requestedAt,
            )
        })
    }

    private static func advance(
        _ sleeper: ManualSleeper,
        by interval: TimeInterval,
    ) async {
        await settle { sleeper.sleeperCount > 0 }
        sleeper.advance(by: interval)
    }

    private static func settle(until condition: @Sendable () async -> Bool) async {
        for _ in 0 ..< 1_000 {
            guard await !condition() else { return }
            await Task.yield()
        }
    }

}
