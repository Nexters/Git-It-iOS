import Testing

@testable import DomainLearningProject

// MARK: - SubmitChoiceAnswerTests

@Suite("SubmitChoiceAnswer")
struct SubmitChoiceAnswerTests {

    // MARK: Internal

    @Test
    func `음수 index는 요청 없이 차단한다`() async throws {
        let repository = SubmitChoiceAnswerRepository(behavior: .succeed(makeResult()))
        let submitChoiceAnswer = SubmitChoiceAnswer(repository: repository)

        await #expect(throws: LearningProjectError.invalidRequest) {
            try await submitChoiceAnswer(projectID: "project-1", questionID: "q1", selectedIndex: -1)
        }
        #expect(await repository.callCount == 0)
    }

    @Test
    func `정확한 index로 정확히 한 번 요청한다`() async throws {
        let repository = SubmitChoiceAnswerRepository(behavior: .succeed(makeResult()))
        let submitChoiceAnswer = SubmitChoiceAnswer(repository: repository)

        _ = try await submitChoiceAnswer(projectID: "project-1", questionID: "q1", selectedIndex: 2)

        #expect(await repository.callCount == 1)
        #expect(await repository.lastIndex == 2)
    }

    @Test
    func `서버의 correct와 해설을 그대로 보존한다`() async throws {
        let result = ChoiceAnswerResult(correct: true, answerIndex: 2, explanation: "설명")
        let repository = SubmitChoiceAnswerRepository(behavior: .succeed(result))
        let submitChoiceAnswer = SubmitChoiceAnswer(repository: repository)

        let outcome = try await submitChoiceAnswer(projectID: "project-1", questionID: "q1", selectedIndex: 2)

        #expect(outcome == result)
    }

    // MARK: Private

    private func makeResult() -> ChoiceAnswerResult {
        ChoiceAnswerResult(correct: false, answerIndex: 0, explanation: "")
    }

}

// MARK: - SubmitChoiceAnswerRepository

private actor SubmitChoiceAnswerRepository: AnswerRepository {

    // MARK: Lifecycle

    init(behavior: Behavior) {
        self.behavior = behavior
    }

    // MARK: Internal

    enum Behavior: Sendable {
        case succeed(ChoiceAnswerResult)
    }

    private(set) var callCount = 0
    private(set) var lastIndex: Int?

    func submitChoiceAnswer(
        projectID _: String,
        questionID _: String,
        selectedIndex: Int,
    ) async throws -> ChoiceAnswerResult {
        callCount += 1
        lastIndex = selectedIndex
        switch behavior {
        case .succeed(let result):
            return result
        }
    }

    func submitEssayAnswer(
        projectID _: String,
        questionID _: String,
        text _: String,
    ) async throws -> EssayAnswerResult {
        EssayAnswerResult(explanation: "", rubric: Rubric(criteria: []))
    }

    // MARK: Private

    private let behavior: Behavior

}
