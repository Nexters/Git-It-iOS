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
    }

}
