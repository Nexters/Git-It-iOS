import Foundation
import Testing

@testable import DomainLearningProject

@Suite("TrackGeneration")
struct TrackGenerationTests {

    // MARK: Internal

    @Test
    func `생성 시작과 프로젝트 연결을 생성 대기 Repository에 위임한다`() async {
        let pendingGenerations = StubPendingGenerationRepository()
        let trackGeneration = Self.makeTrackGeneration(pendingGenerations: pendingGenerations)

        #expect(await trackGeneration.begin(githubRepoURL: Self.url, requestedAt: Self.requestedAt))
        await trackGeneration.attachProjectID("p1", toGithubRepoURL: Self.url)

        #expect(await pendingGenerations.pendingState().record(projectID: "p1")?.status == .inProgress)
        #expect(await trackGeneration.current().activeProjectIDs == ["p1"])
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

        await trackGeneration.end(projectID: "p1")

        #expect(await trackGeneration.current().activeProjectIDs.isEmpty)
    }

    @Test
    func `저장소 URL로 종료하면 그 기록이 사라진다`() async {
        let trackGeneration = Self.makeTrackGeneration()
        _ = await trackGeneration.begin(githubRepoURL: Self.url, requestedAt: Self.requestedAt)

        await trackGeneration.end(githubRepoURL: Self.url)

        #expect(await trackGeneration.current().record(githubRepoURL: Self.url) == nil)
    }

    @Test
    func `저장된 생성 대기 상태를 그대로 조회한다`() async {
        let stored = GenerationState(records: [
            GenerationRecord(githubRepoURL: Self.url, projectID: "p1", requestedAt: Self.requestedAt)
        ])
        let trackGeneration = Self.makeTrackGeneration(
            pendingGenerations: StubPendingGenerationRepository(state: stored)
        )

        #expect(await trackGeneration.current().record(projectID: "p1") != nil)
    }

    @Test
    func `생성 결과를 받으면 완료 시각과 함께 생성 대기 Repository에 반영한다`() async {
        let outcomes = StubGenerationOutcomeRepository()
        let pendingGenerations = StubPendingGenerationRepository()
        let trackGeneration = Self.makeTrackGeneration(
            pendingGenerations: pendingGenerations,
            outcomeRepository: outcomes,
        )
        _ = await trackGeneration.begin(githubRepoURL: Self.url, requestedAt: Self.requestedAt)
        await trackGeneration.attachProjectID("p1", toGithubRepoURL: Self.url)

        outcomes.emit(GenerationOutcome(projectID: "p1", status: .failed))
        await Self.settle(pendingGenerations, until: 1)

        #expect(await pendingGenerations.finishedGenerations == [
            .init(projectID: "p1", status: .failed, finishedAt: Self.requestedAt)
        ])
        #expect(await trackGeneration.current().record(projectID: "p1")?.status == .failed)
    }

    @Test
    func `연산을 여러 번 호출해도 생성 결과 관찰은 한 번만 시작한다`() async {
        let outcomes = StubGenerationOutcomeRepository()
        let pendingGenerations = StubPendingGenerationRepository()
        let trackGeneration = Self.makeTrackGeneration(
            pendingGenerations: pendingGenerations,
            outcomeRepository: outcomes,
        )
        _ = await trackGeneration.begin(githubRepoURL: Self.url, requestedAt: Self.requestedAt)
        await trackGeneration.attachProjectID("p1", toGithubRepoURL: Self.url)
        _ = await trackGeneration.current()
        _ = await trackGeneration.states()

        outcomes.emit(GenerationOutcome(projectID: "p1", status: .completed))
        await Self.settle(pendingGenerations, until: 1)
        for _ in 0 ..< 20 {
            await Task.yield()
        }

        #expect(await pendingGenerations.finishedGenerations.count == 1)
    }

    @Test
    func `관측을 먼저 시작하면 진행 중 상태를 받은 뒤 완료 상태를 이어서 받는다`() async {
        let outcomes = StubGenerationOutcomeRepository()
        let pendingGenerations = StubPendingGenerationRepository()
        let trackGeneration = Self.makeTrackGeneration(
            pendingGenerations: pendingGenerations,
            outcomeRepository: outcomes,
        )
        _ = await trackGeneration.begin(githubRepoURL: Self.url, requestedAt: Self.requestedAt)
        await trackGeneration.attachProjectID("p1", toGithubRepoURL: Self.url)

        var iterator = await trackGeneration.states().makeAsyncIterator()
        let first = await iterator.next()
        #expect(first?.record(projectID: "p1")?.status == .inProgress)

        outcomes.emit(GenerationOutcome(projectID: "p1", status: .completed))
        let second = await iterator.next()
        #expect(second?.record(projectID: "p1")?.status == .completed)
    }

    @Test
    func `관측자 둘이 같은 상태를 받는다`() async {
        let trackGeneration = Self.makeTrackGeneration()
        _ = await trackGeneration.begin(githubRepoURL: Self.url, requestedAt: Self.requestedAt)

        var first = await trackGeneration.states().makeAsyncIterator()
        var second = await trackGeneration.states().makeAsyncIterator()

        let firstValue = await first.next()
        let secondValue = await second.next()
        #expect(firstValue == secondValue)
    }

    // MARK: Private

    private static let url = "https://github.com/owner/repo"
    private static let requestedAt = Date(timeIntervalSince1970: 1_000)

    private static func makeTrackGeneration(
        pendingGenerations: StubPendingGenerationRepository = StubPendingGenerationRepository(),
        outcomeRepository: StubGenerationOutcomeRepository = StubGenerationOutcomeRepository(),
    ) -> TrackGeneration {
        TrackGeneration(
            pendingGenerations: pendingGenerations,
            outcomeRepository: outcomeRepository,
            now: { requestedAt },
        )
    }

    private static func settle(
        _ pendingGenerations: StubPendingGenerationRepository,
        until finishedCount: Int,
    ) async {
        for _ in 0 ..< 100 {
            guard await pendingGenerations.finishedGenerations.count < finishedCount else { return }
            await Task.yield()
        }
    }

}
