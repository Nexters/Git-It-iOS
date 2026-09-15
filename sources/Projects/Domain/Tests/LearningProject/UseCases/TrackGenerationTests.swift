import Foundation
import Testing

@testable import DomainLearningProject

@Suite("TrackGeneration")
struct TrackGenerationTests {

    @Test
    func `완료 통지가 먼저 도착해도 그 뒤에 시작한 관측이 첫 값으로 완료 상태를 받는다`() async {
        let outcomes = StubGenerationOutcomeRepository()
        let trackGeneration = Self.makeTrackGeneration(outcomeRepository: outcomes)

        _ = await trackGeneration.begin(githubRepoURL: Self.url, requestedAt: Self.requestedAt)
        await trackGeneration.attachProjectID("p1", toGithubRepoURL: Self.url)
        await Self.emitAndSettle(outcomes, .init(projectID: "p1", status: .completed), trackGeneration)

        var iterator = await trackGeneration.states().makeAsyncIterator()
        let first = await iterator.next()

        #expect(first?.record(projectID: "p1")?.status == .completed)
    }

    @Test
    func `관측을 먼저 시작하면 진행 중 상태를 받은 뒤 완료 상태를 이어서 받는다`() async {
        let outcomes = StubGenerationOutcomeRepository()
        let trackGeneration = Self.makeTrackGeneration(outcomeRepository: outcomes)

        _ = await trackGeneration.begin(githubRepoURL: Self.url, requestedAt: Self.requestedAt)
        await trackGeneration.attachProjectID("p1", toGithubRepoURL: Self.url)

        var iterator = await trackGeneration.states().makeAsyncIterator()
        let first = await iterator.next()
        #expect(first?.record(projectID: "p1")?.status == .inProgress)

        await Self.emitAndSettle(outcomes, .init(projectID: "p1", status: .completed), trackGeneration)
        let second = await iterator.next()
        #expect(second?.record(projectID: "p1")?.status == .completed)
    }

    @Test
    func `관측자 둘이 같은 시점에 같은 상태를 받는다`() async {
        let trackGeneration = Self.makeTrackGeneration()
        _ = await trackGeneration.begin(githubRepoURL: Self.url, requestedAt: Self.requestedAt)

        var first = await trackGeneration.states().makeAsyncIterator()
        var second = await trackGeneration.states().makeAsyncIterator()

        let firstValue = await first.next()
        let secondValue = await second.next()
        #expect(firstValue == secondValue)
    }

    @Test
    func `같은 저장소 URL로는 진행 중 생성을 두 번 시작할 수 없다`() async {
        let trackGeneration = Self.makeTrackGeneration()

        #expect(await trackGeneration.begin(githubRepoURL: Self.url, requestedAt: Self.requestedAt))
        #expect(await trackGeneration.begin(githubRepoURL: Self.url, requestedAt: Self.requestedAt) == false)
    }

    @Test
    func `생성을 종료하면 활성 프로젝트에서 빠진다`() async {
        let trackGeneration = Self.makeTrackGeneration()
        _ = await trackGeneration.begin(githubRepoURL: Self.url, requestedAt: Self.requestedAt)
        await trackGeneration.attachProjectID("p1", toGithubRepoURL: Self.url)
        #expect(await trackGeneration.current().activeProjectIDs == ["p1"])

        await trackGeneration.end(projectID: "p1")

        #expect(await trackGeneration.current().activeProjectIDs.isEmpty)
    }

    @Test
    func `보존한 상태를 다시 불러와 복원한다`() async {
        let stored = GenerationState(records: [
            GenerationRecord(githubRepoURL: Self.url, projectID: "p1", requestedAt: Self.requestedAt),
        ])
        let trackGeneration = Self.makeTrackGeneration(
            stateRepository: StubGenerationStateRepository(stored: stored)
        )

        #expect(await trackGeneration.current().record(projectID: "p1") != nil)
    }

    @Test
    func `관측을 반복 등록하고 해제해도 관측자 목록이 늘어나지 않는다`() async {
        let trackGeneration = Self.makeTrackGeneration()
        _ = await trackGeneration.current()

        for _ in 0 ..< 5 {
            let stream = await trackGeneration.states()
            var iterator = stream.makeAsyncIterator()
            _ = await iterator.next()
        }
        await Self.settle(trackGeneration)

        #expect(await trackGeneration.coordinator.observerCount == 0)
    }

    // MARK: Private

    private static let url = "https://github.com/owner/repo"
    private static let requestedAt = Date(timeIntervalSince1970: 1_000)

    private static func makeTrackGeneration(
        stateRepository: StubGenerationStateRepository = StubGenerationStateRepository(),
        outcomeRepository: StubGenerationOutcomeRepository = StubGenerationOutcomeRepository(),
    ) -> TrackGeneration {
        TrackGeneration(
            stateRepository: stateRepository,
            outcomeRepository: outcomeRepository,
            waitPolicy: GenerationWaitPolicy(minimumWait: 1, retentionLimit: 100_000),
            now: { requestedAt },
        )
    }

    private static func emitAndSettle(
        _ outcomes: StubGenerationOutcomeRepository,
        _ outcome: GenerationOutcome,
        _ trackGeneration: TrackGeneration,
    ) async {
        outcomes.emit(outcome)
        await settle(trackGeneration)
    }

    private static func settle(_ trackGeneration: TrackGeneration) async {
        for _ in 0 ..< 20 {
            await Task.yield()
            _ = await trackGeneration.current()
        }
    }

}
