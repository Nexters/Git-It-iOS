import Testing

@testable import CompositionAdapter
@testable import DataLearningProject
@testable import DomainLearningProject

// MARK: - AnswerRepositoryAdapterTests

@Suite("AnswerRepositoryAdapter")
struct AnswerRepositoryAdapterTests {

    @Test
    func `객관식 응답 DTO를 Domain ChoiceAnswerResult로 변환한다`() async throws {
        let remote = StubAnswerRemote(choiceResult: .success(SubmitChoiceAnswerResponseDTO(
            questionID: "question-1",
            correct: true,
            answerIndex: 1,
            explanation: "설명",
        )))
        let adapter = AnswerRepositoryAdapter(remote: remote)

        let result = try await adapter.submitChoiceAnswer(projectID: "project-1", questionID: "question-1", selectedIndex: 1)

        #expect(result.correct)
        #expect(result.answerIndex == 1)
    }

    @Test
    func `서술형 응답 DTO를 Domain EssayAnswerResult로 변환한다`() async throws {
        let remote = StubAnswerRemote(essayResult: .success(SubmitEssayAnswerResponseDTO(
            questionID: "question-1",
            explanation: "설명",
            rubric: RubricResponseDTO(score: 90, feedback: "good"),
        )))
        let adapter = AnswerRepositoryAdapter(remote: remote)

        let result = try await adapter.submitEssayAnswer(projectID: "project-1", questionID: "question-1", text: "내 답")

        #expect(result.rubric.criteria == ["good"])
    }

    @Test
    func `Data 오류를 Domain 오류로 변환한다`() async throws {
        let remote = StubAnswerRemote(choiceResult: .failure(.questionUnavailable))
        let adapter = AnswerRepositoryAdapter(remote: remote)

        await #expect(throws: LearningProjectError.questionUnavailable) {
            try await adapter.submitChoiceAnswer(projectID: "project-1", questionID: "missing", selectedIndex: 0)
        }
    }

}

// MARK: - StubAnswerRemote

private struct StubAnswerRemote: AnswerRemote {
    var choiceResult = Result<SubmitChoiceAnswerResponseDTO, DataLearningProjectError>.failure(.unexpectedStatus)
    var essayResult = Result<SubmitEssayAnswerResponseDTO, DataLearningProjectError>.failure(.unexpectedStatus)

    func submitChoiceAnswer(
        projectID _: String,
        questionID _: String,
        request _: SubmitChoiceAnswerRequestDTO,
    ) async throws -> SubmitChoiceAnswerResponseDTO {
        try choiceResult.get()
    }

    func submitEssayAnswer(
        projectID _: String,
        questionID _: String,
        request _: SubmitEssayAnswerRequestDTO,
    ) async throws -> SubmitEssayAnswerResponseDTO {
        try essayResult.get()
    }
}
