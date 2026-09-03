import Testing

@testable import DomainLearningProject

// MARK: - FetchLearningSetTests

@Suite("FetchLearningSet")
struct FetchLearningSetTests {
    @Test
    func `서버 순서를 유지한 채 모든 문제 형식을 전달한다`() async throws {
        let questions = [
            Question(
                questionID: "q1",
                prompt: "prompt-1",
                format: .multipleChoice,
                choices: ["a", "b"],
                sources: [],
                myAnswer: nil,
            ),
            Question(
                questionID: "q2",
                prompt: "prompt-2",
                format: .essay,
                choices: nil,
                sources: [],
                myAnswer: nil,
            ),
        ]
        let set = LearningSet(setID: "set-1", title: "title", description: "description", questions: questions)
        let fetchLearningSet = FetchLearningSet(repository: FetchLearningSetRepository(behavior: .succeed(set)))

        let result = try await fetchLearningSet(projectID: "project-1", setID: "set-1")

        #expect(result.questions.map(\.questionID) == ["q1", "q2"])
        #expect(result.questions[0].format == .multipleChoice)
        #expect(result.questions[1].format == .essay)
    }

    @Test
    func `제출 전에는 myAnswer가 노출되지 않는다`() async throws {
        let question = Question(
            questionID: "q1",
            prompt: "prompt",
            format: .multipleChoice,
            choices: ["a"],
            sources: [],
            myAnswer: nil,
        )
        let set = LearningSet(
            setID: "set-1",
            title: "title",
            description: "description",
            questions: [question],
        )
        let fetchLearningSet = FetchLearningSet(repository: FetchLearningSetRepository(behavior: .succeed(set)))

        let result = try await fetchLearningSet(projectID: "project-1", setID: "set-1")

        #expect(result.questions[0].myAnswer == nil)
    }

    @Test
    func `세트 미존재 오류를 그대로 전파한다`() async throws {
        let fetchLearningSet = FetchLearningSet(
            repository: FetchLearningSetRepository(behavior: .fail(.learningSetUnavailable))
        )

        await #expect(throws: LearningProjectError.learningSetUnavailable) {
            try await fetchLearningSet(projectID: "project-1", setID: "set-1")
        }
    }
}

// MARK: - FetchLearningSetRepository

private struct FetchLearningSetRepository: LearningSetRepository {
    enum Behavior: Sendable {
        case succeed(LearningSet)
        case fail(LearningProjectError)
    }

    let behavior: Behavior

    func fetchSet(
        projectID _: String,
        setID _: String,
    ) async throws -> LearningSet {
        switch behavior {
        case .succeed(let set):
            return set

        case .fail(let error):
            throw error
        }
    }
}
