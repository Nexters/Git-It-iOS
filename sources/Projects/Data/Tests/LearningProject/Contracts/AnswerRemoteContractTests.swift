import Testing

@testable import DataLearningProject

@Suite("AnswerRemote 계약")
struct LearningProjectAnswerContractTests {

    @Test
    func `객관식 답변을 제출한다`() async throws {
        let remote = LearningProjectRemoteProbe()

        let response = try await remote.submitChoiceAnswer(
            projectID: "project-1",
            questionID: "question-1",
            request: SubmitChoiceAnswerRequestDTO(selectedIndex: 0),
        )

        #expect(response.questionID == "question-1")
        #expect(await remote.recordedCalls() == [.submitChoiceAnswer])
    }

    @Test
    func `서술형 답변 응답에는 correct 필드가 없다`() {
        #expect(!String(reflecting: SubmitEssayAnswerResponseDTO.self).contains("correct"))

        let mirror = Mirror(reflecting: SubmitEssayAnswerResponseDTO(
            questionID: "question-1",
            explanation: "",
            rubric: RubricResponseDTO(score: 0, feedback: ""),
        ))

        #expect(!mirror.children.compactMap(\.label).contains("correct"))
    }

    @Test
    func `서술형 답변을 제출한다`() async throws {
        let remote = LearningProjectRemoteProbe()

        let response = try await remote.submitEssayAnswer(
            projectID: "project-1",
            questionID: "question-1",
            request: SubmitEssayAnswerRequestDTO(text: "답변"),
        )

        #expect(response.questionID == "question-1")
        #expect(await remote.recordedCalls() == [.submitEssayAnswer])
    }

}
