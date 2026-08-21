import Testing

@testable import CompositionAdapter
@testable import DataLearningProject
@testable import DomainLearningProject

@Suite("LearningSetRepositoryAdapter")
struct LearningSetRepositoryAdapterTests {

    @Test
    func `DTO를 Domain LearningSet으로 서버 순서 그대로 변환한다`() async throws {
        let remote = StubLearningSetRemote(result: .success(LearningSetResponseDTO(
            setID: "set-1",
            title: "제목",
            description: "설명",
            orientation: "front",
            level: "L1",
            questions: [
                QuestionResponseDTO(
                    questionID: "question-1",
                    format: "multiple_choice",
                    text: "질문",
                    choices: ["A", "B"],
                    sources: [SourceResponseDTO(file: "a.swift", startLine: 1, endLine: 2, symbol: "foo", summary: nil, url: "https://example.com")],
                    myAnswer: nil,
                ),
                QuestionResponseDTO(
                    questionID: "question-2",
                    format: "essay",
                    text: "질문2",
                    choices: [],
                    sources: [],
                    myAnswer: nil,
                ),
            ],
        )))
        let adapter = LearningSetRepositoryAdapter(remote: remote)

        let set = try await adapter.fetchSet(projectID: "project-1", setID: "set-1")

        #expect(set.setID == "set-1")
        #expect(set.questions.map(\.questionID) == ["question-1", "question-2"])
        #expect(set.questions[0].format == .multipleChoice)
        #expect(set.questions[1].format == .essay)
        #expect(set.questions[0].choices == ["A", "B"])
        #expect(set.questions[1].choices == nil)
    }

    @Test
    func `Data 오류를 Domain 오류로 변환한다`() async throws {
        let remote = StubLearningSetRemote(result: .failure(.learningSetUnavailable))
        let adapter = LearningSetRepositoryAdapter(remote: remote)

        await #expect(throws: LearningProjectError.learningSetUnavailable) {
            try await adapter.fetchSet(projectID: "project-1", setID: "missing")
        }
    }

}

// MARK: - StubLearningSetRemote

private struct StubLearningSetRemote: LearningSetRemote {
    let result: Result<LearningSetResponseDTO, DataLearningProjectError>

    func fetchLearningSet(projectID _: String, setID _: String) async throws -> LearningSetResponseDTO {
        try result.get()
    }
}
