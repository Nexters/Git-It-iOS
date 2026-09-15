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
        _ = assembly.trackGeneration as any TrackGenerationUseCase
    }

    @Test
    func `push 진입점으로 수신한 payload가 생성 추적 상태에 완료로 반영된다`() async throws {
        let assembly = LearningProjectAssembly(
            baseURL: try #require(URL(string: "https://api.git-it.example.com")),
            accessTokenProvider: { nil },
            sharedDefaults: try #require(UserDefaults(suiteName: UUID().uuidString)),
        )
        let trackGeneration = assembly.trackGeneration
        let githubRepoURL = "https://github.com/owner/repo"
        _ = await trackGeneration.begin(githubRepoURL: githubRepoURL, requestedAt: Date())
        await trackGeneration.attachProjectID("project-1", toGithubRepoURL: githubRepoURL)

        var iterator = await trackGeneration.states().makeAsyncIterator()
        _ = await iterator.next()

        await assembly.ingestGenerationOutcomePayload(["projectId": "project-1", "status": "completed"])

        var status: GenerationRecord.Status?
        while let state = await iterator.next() {
            status = state.record(projectID: "project-1")?.status
            if status == .completed { break }
        }
        #expect(status == .completed)
    }

}
