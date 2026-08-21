import Testing

@testable import DomainLearningProject

// MARK: - SubmitEssayAnswerTests

@Suite("SubmitEssayAnswer")
struct SubmitEssayAnswerTests {
    @Test
    func `공백만 있으면 요청 없이 차단한다`() async throws {
        let repository = SubmitEssayAnswerRepository()
        let submitEssayAnswer = SubmitEssayAnswer(repository: repository)

        await #expect(throws: LearningProjectError.invalidRequest) {
            try await submitEssayAnswer(projectID: "project-1", questionID: "q1", text: "   \n")
        }
        #expect(await repository.callCount == 0)
    }

    @Test
    func `2000자를 초과하면 차단한다`() async throws {
        let repository = SubmitEssayAnswerRepository()
        let submitEssayAnswer = SubmitEssayAnswer(repository: repository)
        let overLimit = String(repeating: "a", count: 2001)

        await #expect(throws: LearningProjectError.invalidRequest) {
            try await submitEssayAnswer(projectID: "project-1", questionID: "q1", text: overLimit)
        }
    }

    @Test
    func `2000자는 경계값으로 허용한다`() async throws {
        let repository = SubmitEssayAnswerRepository()
        let submitEssayAnswer = SubmitEssayAnswer(repository: repository)
        let atLimit = String(repeating: "a", count: 2000)

        _ = try await submitEssayAnswer(projectID: "project-1", questionID: "q1", text: atLimit)

        #expect(await repository.callCount == 1)
    }

    @Test
    func `explanation과 rubric을 그대로 보존한다`() async throws {
        let repository = SubmitEssayAnswerRepository()
        let submitEssayAnswer = SubmitEssayAnswer(repository: repository)

        let result = try await submitEssayAnswer(projectID: "project-1", questionID: "q1", text: "답변")

        #expect(result.rubric.criteria == ["기준1"])
    }
}

// MARK: - SubmitEssayAnswerRepository

private actor SubmitEssayAnswerRepository: AnswerRepository {
    private(set) var callCount = 0

    func submitChoiceAnswer(
        projectID _: String,
        questionID _: String,
        selectedIndex _: Int,
    ) async throws -> ChoiceAnswerResult {
        ChoiceAnswerResult(correct: false, answerIndex: 0, explanation: "")
    }

    func submitEssayAnswer(
        projectID _: String,
        questionID _: String,
        text _: String,
    ) async throws -> EssayAnswerResult {
        callCount += 1
        return EssayAnswerResult(explanation: "설명", rubric: Rubric(criteria: ["기준1"]))
    }
}
