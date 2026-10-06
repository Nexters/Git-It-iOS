import Foundation
import Testing
@testable import CompositionAdapter
@testable import DataLearningProject
@testable import DomainLearningProject

struct LearningProjectAssemblyTests {

    @Test
    func `live 그래프 생성이 성공하고 노출 property가 모두 UseCase Protocol 타입이다`() throws {
        let assembly = LearningProjectAssembly(
            baseURL: try #require(URL(string: "https://api.git-it.example.com")),
            accessTokenProvider: { nil },
        )

        _ = assembly.fetchLearningProjects as any FetchLearningProjectsUseCase
        _ = assembly.fetchLearningProjectDetail as any FetchLearningProjectDetailUseCase
        _ = assembly.createLearningProject as any CreateLearningProjectUseCase
        _ = assembly.deleteLearningProject as any DeleteLearningProjectUseCase
        _ = assembly.fetchLearningSet as any FetchLearningSetUseCase
        _ = assembly.submitChoiceAnswer as any SubmitChoiceAnswerUseCase
        _ = assembly.submitEssayAnswer as any SubmitEssayAnswerUseCase
        _ = assembly.setQuestionBookmark as any SetQuestionBookmarkUseCase
        _ = assembly.fetchBookmarkedQuestions as any FetchBookmarkedQuestionsUseCase
        _ = assembly.observeGenerationOutcomes as any ObserveGenerationOutcomesUseCase
    }

    @Test
    func `push 진입점으로 수신한 payload가 관찰 Use Case의 스트림으로 전달된다`() async throws {
        let assembly = LearningProjectAssembly(
            baseURL: try #require(URL(string: "https://api.git-it.example.com")),
            accessTokenProvider: { nil },
        )

        let stream = await assembly.observeGenerationOutcomes()
        var iterator = stream.makeAsyncIterator()

        await assembly.ingestGenerationOutcomePayload(["projectId": "project-1", "status": "completed"])

        let outcome = await iterator.next()
        #expect(outcome == GenerationOutcome(projectID: "project-1", status: .completed))
    }

}
