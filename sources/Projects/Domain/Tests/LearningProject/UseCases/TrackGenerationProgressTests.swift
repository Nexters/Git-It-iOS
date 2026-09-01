import Foundation
import Testing

@testable import DomainLearningProject

@Suite("TrackGenerationProgress")
struct TrackGenerationProgressTests {
    @Test
    func `begin으로 기록한 진행 상태를 current가 그대로 반환한다`() async {
        let repository = StubGenerationProgressRepository()
        let useCase = TrackGenerationProgress(progressRepository: repository)
        let requestedAt = Date(timeIntervalSince1970: 1_000)

        await useCase.begin(projectID: "project-1", requestedAt: requestedAt)

        let current = await useCase.current()
        #expect(current == GenerationProgress(projectID: "project-1", requestedAt: requestedAt))
    }

    @Test
    func `두 번 begin해도 마지막 요청 1건만 남는다`() async {
        let repository = StubGenerationProgressRepository()
        let useCase = TrackGenerationProgress(progressRepository: repository)

        await useCase.begin(projectID: "project-1", requestedAt: Date(timeIntervalSince1970: 1_000))
        await useCase.begin(projectID: "project-2", requestedAt: Date(timeIntervalSince1970: 2_000))

        let current = await useCase.current()
        #expect(current?.projectID == "project-2")
        #expect(current?.requestedAt == Date(timeIntervalSince1970: 2_000))
    }

    @Test
    func `end 이후에는 current가 nil을 반환한다`() async {
        let repository = StubGenerationProgressRepository()
        let useCase = TrackGenerationProgress(progressRepository: repository)
        await useCase.begin(projectID: "project-1", requestedAt: Date(timeIntervalSince1970: 1_000))

        await useCase.end()

        let current = await useCase.current()
        #expect(current == nil)
    }

    @Test
    func `기록된 적이 없으면 current가 nil을 반환한다`() async {
        let repository = StubGenerationProgressRepository()
        let useCase = TrackGenerationProgress(progressRepository: repository)

        let current = await useCase.current()

        #expect(current == nil)
        let calls = await repository.calls
        #expect(calls == [.load])
    }
}
