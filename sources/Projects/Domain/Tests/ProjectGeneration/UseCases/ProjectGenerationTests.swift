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
    func `요청만 호출하면 결과 관찰을 시작하지 않는다`() async throws {
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
    func `생성이 실패하면 즉시 failed를 방출한다`() async throws {
        let fixture = Fixture()
        _ = try await fixture.generation.request(Self.request)
        var states = await fixture.generation.states().makeAsyncIterator()
        _ = await states.next()

        fixture.outcomes.emit(Self.outcome(
            "p1",
            .failed,
        ))
        let failed = await Self.next(&states) { $0.requests.first?.phase == .failed }

        #expect(failed?.requests.first?.projectID == "p1")
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
    func `같은 결과가 두 번 도착해도 기록 전이는 한 번이다`() async throws {
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
    func `동기화하면 보관 기한이 지난 기록을 정리한다`() async throws {
        let fixture = Fixture()
        _ = try await fixture.generation.request(Self.request)
        var states = await fixture.generation.states().makeAsyncIterator()
        _ = await states.next()

        fixture.sleeper.advance(by: 3_601)
        await fixture.generation.synchronize()
        let state = await Self.next(&states) { $0.requests.isEmpty }

        #expect(state?.requests.isEmpty == true)
    }

    @Test
    func `프로젝트를 해제하면 기록을 지운다`() async throws {
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
    }

    @Test
    func `기록이 없는 프로젝트를 해제해도 오류 없이 끝난다`() async {
        let fixture = Fixture()

        await fixture.generation.release("p-unknown")

        #expect(await fixture.pendingGenerations.state.records.isEmpty)
    }

    @Test
    func `생성 결과가 도착하면 그 프로젝트 식별자를 도착 알림으로 방출한다`() async throws {
        let fixture = Fixture()
        _ = try await fixture.generation.request(Self.request)
        var arrivals = await fixture.generation.outcomeArrivals().makeAsyncIterator()

        fixture.outcomes.emit(Self.outcome(
            "p1",
            .completed,
        ))

        #expect(await arrivals.next() == "p1")
    }

    @Test
    func `생성 기록이 없는 프로젝트의 결과도 도착 알림으로 방출한다`() async {
        let fixture = Fixture()
        var arrivals = await fixture.generation.outcomeArrivals().makeAsyncIterator()

        fixture.outcomes.emit(Self.outcome(
            "p-unknown",
            .completed,
        ))

        #expect(await arrivals.next() == "p-unknown")
    }

    @Test
    func `보존한 결과를 다시 반영할 때는 도착 알림을 방출하지 않는다`() async {
        let fixture = Fixture(state: Self.unattachedState(repositoryURLs: [Self.request.repositoryURL]))
        var states = await fixture.generation.states().makeAsyncIterator()
        _ = await states.next()
        var arrivals = await fixture.generation.outcomeArrivals().makeAsyncIterator()
        fixture.outcomes.emit(Self.outcome(
            "p1",
            .completed,
        ))
        #expect(await arrivals.next() == "p1")

        await fixture.pendingGenerations.attachProjectID(
            "p1",
            toRepositoryURL: Self.request.repositoryURL,
        )
        await fixture.generation.synchronize()
        _ = await Self.next(&states) { $0.requests.first?.phase == .ready }
        fixture.outcomes.emit(Self.outcome(
            "p2",
            .completed,
        ))

        #expect(await arrivals.next() == "p2")
    }

    @Test
    func `도착 알림은 생성 기록 반영을 마친 뒤 방출한다`() async throws {
        let fixture = Fixture()
        _ = try await fixture.generation.request(Self.request)
        var arrivals = await fixture.generation.outcomeArrivals().makeAsyncIterator()

        fixture.outcomes.emit(Self.outcome(
            "p1",
            .completed,
        ))
        _ = await arrivals.next()
        var states = await fixture.generation.states().makeAsyncIterator()

        #expect(await states.next()?.requests.first?.phase == .ready)
    }

    @Test
    func `같은 프로젝트의 같은 결과가 다시 도착하면 도착 알림을 다시 방출하지 않는다`() async {
        let fixture = Fixture()
        var arrivals = await fixture.generation.outcomeArrivals().makeAsyncIterator()

        fixture.outcomes.emit(Self.outcome(
            "p1",
            .completed,
        ))
        fixture.outcomes.emit(Self.outcome(
            "p1",
            .completed,
            arrivedAt: Self.requestedAt.addingTimeInterval(1),
        ))
        fixture.outcomes.emit(Self.outcome(
            "p2",
            .completed,
        ))

        #expect(await arrivals.next() == "p1")
        #expect(await arrivals.next() == "p2")
    }

    @Test
    func `같은 프로젝트라도 상태가 다른 결과는 도착 알림을 방출한다`() async {
        let fixture = Fixture()
        var arrivals = await fixture.generation.outcomeArrivals().makeAsyncIterator()

        fixture.outcomes.emit(Self.outcome(
            "p1",
            .failed,
        ))
        fixture.outcomes.emit(Self.outcome(
            "p1",
            .completed,
        ))

        #expect(await arrivals.next() == "p1")
        #expect(await arrivals.next() == "p1")
    }

    @Test
    func `보관 기한이 지난 뒤 같은 결과가 다시 도착하면 도착 알림을 방출한다`() async {
        let fixture = Fixture()
        var arrivals = await fixture.generation.outcomeArrivals().makeAsyncIterator()
        fixture.outcomes.emit(Self.outcome(
            "p1",
            .completed,
        ))
        #expect(await arrivals.next() == "p1")

        fixture.sleeper.advance(by: 3_601)
        fixture.outcomes.emit(Self.outcome(
            "p1",
            .completed,
            arrivedAt: fixture.sleeper.now,
        ))

        #expect(await arrivals.next() == "p1")
    }

    @Test
    func `로그아웃한 뒤 같은 결과가 다시 도착하면 도착 알림을 방출한다`() async {
        let fixture = Fixture(state: Self.unattachedState(repositoryURLs: [Self.request.repositoryURL]))
        var states = await fixture.generation.states().makeAsyncIterator()
        _ = await states.next()
        var arrivals = await fixture.generation.outcomeArrivals().makeAsyncIterator()
        fixture.outcomes.emit(Self.outcome(
            "p1",
            .completed,
        ))
        #expect(await arrivals.next() == "p1")

        fixture.signedOutContinuation.yield(())
        _ = await Self.next(&states) { $0.requests.isEmpty }
        fixture.outcomes.emit(Self.outcome(
            "p1",
            .completed,
        ))

        #expect(await arrivals.next() == "p1")
    }

    @Test
    func `동기화하면 알림 센터에 남은 결과로 진행 중 기록을 결과 상태로 바꾼다`() async throws {
        let fixture = Fixture()
        _ = try await fixture.generation.request(Self.request)
        var states = await fixture.generation.states().makeAsyncIterator()
        _ = await states.next()
        fixture.outcomes.setDeliveredOutcomes([Self.outcome(
            "p1",
            .failed,
        )])

        await fixture.generation.synchronize()
        let state = await Self.next(&states) { $0.requests.first?.phase == .failed }

        #expect(state?.requests.first?.projectID == "p1")
    }

    @Test
    func `알림 센터 결과로 반영해도 도착 알림을 방출하지 않는다`() async throws {
        let fixture = Fixture()
        _ = try await fixture.generation.request(Self.request)
        var arrivals = await fixture.generation.outcomeArrivals().makeAsyncIterator()
        fixture.outcomes.setDeliveredOutcomes([Self.outcome(
            "p1",
            .completed,
        )])

        await fixture.generation.synchronize()
        fixture.outcomes.emit(Self.outcome(
            "p2",
            .completed,
        ))

        #expect(await arrivals.next() == "p2")
        #expect(await fixture.pendingGenerations.state.record(projectID: "p1")?.status == .completed)
    }

    @Test
    func `기록에 없는 프로젝트의 알림 센터 결과는 기록을 바꾸지 않는다`() async throws {
        let fixture = Fixture()
        _ = try await fixture.generation.request(Self.request)
        fixture.outcomes.setDeliveredOutcomes([Self.outcome(
            "p-unknown",
            .completed,
        )])

        await fixture.generation.synchronize()

        #expect(await fixture.pendingGenerations.state.record(projectID: "p1")?.status == .inProgress)
        #expect(await fixture.pendingGenerations.state.record(projectID: "p-unknown") == nil)
    }

    @Test
    func `알림 센터로 반영한 결과가 다시 도착해도 도착 알림을 방출하지 않는다`() async throws {
        let fixture = Fixture()
        _ = try await fixture.generation.request(Self.request)
        var arrivals = await fixture.generation.outcomeArrivals().makeAsyncIterator()
        fixture.outcomes.setDeliveredOutcomes([Self.outcome(
            "p1",
            .completed,
        )])

        await fixture.generation.synchronize()
        fixture.outcomes.emit(Self.outcome(
            "p1",
            .completed,
        ))
        fixture.outcomes.emit(Self.outcome(
            "p2",
            .completed,
        ))

        #expect(await arrivals.next() == "p2")
    }

    @Test
    func `현재 상태 조회는 보관 기한이 지난 기록을 빼고 기록 상태를 단계로 바꿔 돌려준다`() async throws {
        let expiredAt = Self.requestedAt.addingTimeInterval(-GenerationWaitPolicy.standard.retentionLimit - 1)
        let fixture = Fixture(state: GenerationState(records: [
            GenerationRecord(
                repositoryURL: "https://github.com/owner/expired",
                projectID: "p0",
                requestedAt: expiredAt,
            ),
            GenerationRecord(
                repositoryURL: "https://github.com/owner/progress",
                requestedAt: Self.requestedAt,
            ),
            GenerationRecord(
                repositoryURL: "https://github.com/owner/ready",
                projectID: "p2",
                requestedAt: Self.requestedAt,
                status: .completed,
                finishedAt: Self.requestedAt,
            ),
            GenerationRecord(
                repositoryURL: "https://github.com/owner/failed",
                projectID: "p3",
                requestedAt: Self.requestedAt,
                status: .failed,
                finishedAt: Self.requestedAt,
            ),
        ]))

        let state = try await fixture.generation.currentState()

        #expect(state.requests.map(\.repositoryURL) == [
            "https://github.com/owner/progress",
            "https://github.com/owner/ready",
            "https://github.com/owner/failed",
        ])
        #expect(state.requests.map(\.phase) == [.inProgress, .ready, .failed])
        #expect(state.hasRequestInProgress)
    }

    @Test
    func `현재 상태 조회는 결과·저장소 변경 관찰과 만료 타이머를 시작하지 않는다`() async throws {
        let fixture = Fixture()
        _ = try await fixture.generation.request(Self.request)

        _ = try await fixture.generation.currentState()
        fixture.outcomes.emit(Self.outcome(
            "p1",
            .completed,
        ))
        for _ in 0 ..< 50 {
            await Task.yield()
        }

        #expect(await fixture.pendingGenerations.subscriberCount == 0)
        #expect(fixture.sleeper.sleeperCount == 0)
        #expect(await fixture.pendingGenerations.finishedProjectIDs.isEmpty)
    }

    @Test
    func `현재 상태 조회는 저장소가 알린 stateUnavailable을 그대로 전달한다`() async {
        let fixture = Fixture(confirmationFailure: ProjectGenerationError.stateUnavailable)

        await #expect(throws: ProjectGenerationError.stateUnavailable) {
            try await fixture.generation.currentState()
        }
    }

    @Test
    func `현재 상태 조회는 저장소의 다른 오류도 stateUnavailable로 알린다`() async {
        let fixture = Fixture(confirmationFailure: CancellationError())

        await #expect(throws: ProjectGenerationError.stateUnavailable) {
            try await fixture.generation.currentState()
        }
    }

    // MARK: Private

    private struct Fixture {

        // MARK: Lifecycle

        init(
            repository: StubProjectGenerationRepository = StubProjectGenerationRepository(),
            state: GenerationState = GenerationState(),
            confirmationFailure: (any Error)? = nil,
        ) {
            let outcomes = StubGenerationOutcomeRepository()
            let sleeper = ManualSleeper(now: ProjectGenerationTests.requestedAt)
            let pendingGenerations = InMemoryPendingGenerationRepository(
                state: state,
                confirmationFailure: confirmationFailure,
                now: { sleeper.now },
            )
            let (signedOut, signedOutContinuation) = AsyncStream<Void>.makeStream()
            self.repository = repository
            self.pendingGenerations = pendingGenerations
            self.outcomes = outcomes
            self.sleeper = sleeper
            self.signedOutContinuation = signedOutContinuation
            generation = ProjectGeneration(
                repository: repository,
                pendingGenerations: pendingGenerations,
                outcomes: outcomes,
                signedOutEvents: { signedOut },
                now: { sleeper.now },
                sleep: { try await sleeper.sleep($0) },
            )
        }

        // MARK: Internal

        let repository: StubProjectGenerationRepository
        let pendingGenerations: InMemoryPendingGenerationRepository
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
