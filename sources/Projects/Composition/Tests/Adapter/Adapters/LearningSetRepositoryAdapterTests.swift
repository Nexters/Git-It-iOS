import Foundation
import Testing

@testable import CompositionAdapter
@testable import DataLearningProject
@testable import DomainLearningProject

// MARK: - LearningSetRepositoryAdapterTests

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
                    sources: [SourceResponseDTO(
                        file: "a.swift",
                        startLine: 1,
                        endLine: 2,
                        symbol: "foo",
                        summary: nil,
                        url: "https://example.com",
                    )],
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
    func `세트 설명을 복원한다`() async throws {
        let remote = StubLearningSetRemote(result: .success(Self.responseDTO()))
        let adapter = LearningSetRepositoryAdapter(remote: remote)

        let set = try await adapter.fetchSet(projectID: "project-1", setID: "set-1")

        #expect(set.description == "세트 설명")
    }

    @Test
    func `출처 배열 전체를 순서대로 복원한다`() async throws {
        let remote = StubLearningSetRemote(result: .success(Self.responseDTO()))
        let adapter = LearningSetRepositoryAdapter(remote: remote)

        let set = try await adapter.fetchSet(projectID: "project-1", setID: "set-1")

        #expect(set.questions[0].sources.count == 2)
        #expect(set.questions[0].sources.map(\.filePath) == ["a.swift", "b.swift"])
        #expect(set.questions[1].sources.isEmpty)
    }

    @Test
    func `각 출처의 줄 번호와 심볼과 설명을 복원한다`() async throws {
        let remote = StubLearningSetRemote(result: .success(Self.responseDTO()))
        let adapter = LearningSetRepositoryAdapter(remote: remote)

        let set = try await adapter.fetchSet(projectID: "project-1", setID: "set-1")
        let source = try #require(set.questions[0].sources.first)

        #expect(source.filePath == "a.swift")
        #expect(source.startLine == 1)
        #expect(source.endLine == 2)
        #expect(source.symbol == "foo")
        #expect(source.summary == "출처 설명")
        #expect(source.referenceURL == "https://example.com")
    }

    @Test
    func `객관식 기존 답변의 선택 index와 정답 여부를 복원한다`() async throws {
        let remote = StubLearningSetRemote(result: .success(Self.responseDTO()))
        let adapter = LearningSetRepositoryAdapter(remote: remote)

        let set = try await adapter.fetchSet(projectID: "project-1", setID: "set-1")
        let answer = try #require(set.questions[0].myAnswer)

        #expect(answer.selectedIndex == 1)
        #expect(answer.text == nil)
        #expect(answer.correct == true)
    }

    @Test
    func `서술형 기존 답변의 텍스트를 복원하고 정답 여부를 비운다`() async throws {
        let remote = StubLearningSetRemote(result: .success(Self.responseDTO()))
        let adapter = LearningSetRepositoryAdapter(remote: remote)

        let set = try await adapter.fetchSet(projectID: "project-1", setID: "set-1")
        let answer = try #require(set.questions[1].myAnswer)

        #expect(answer.text == "작성한 답안")
        #expect(answer.selectedIndex == nil)
        #expect(answer.correct == nil)
    }

    @Test
    func `기존 답변이 없는 문제는 myAnswer를 비운다`() async throws {
        let remote = StubLearningSetRemote(result: .success(Self.responseDTO()))
        let adapter = LearningSetRepositoryAdapter(remote: remote)

        let set = try await adapter.fetchSet(projectID: "project-1", setID: "set-1")

        #expect(set.questions[2].myAnswer == nil)
    }

    @Test
    func `문제 배열의 서버 순서를 재정렬하지 않는다`() async throws {
        let remote = StubLearningSetRemote(result: .success(Self.responseDTO()))
        let adapter = LearningSetRepositoryAdapter(remote: remote)

        let set = try await adapter.fetchSet(projectID: "project-1", setID: "set-1")

        #expect(set.questions.map(\.questionID) == ["question-1", "question-2", "question-3"])
        #expect(set.questions[0].choices == ["A", "B", "C"])
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

// MARK: - Fixture

extension LearningSetRepositoryAdapterTests {

    fileprivate static func responseDTO() -> LearningSetResponseDTO {
        LearningSetResponseDTO(
            setID: "set-1",
            title: "제목",
            description: "세트 설명",
            orientation: "front",
            level: "L1",
            questions: [
                QuestionResponseDTO(
                    questionID: "question-1",
                    format: "multiple_choice",
                    text: "질문",
                    choices: ["A", "B", "C"],
                    sources: [
                        SourceResponseDTO(
                            file: "a.swift",
                            startLine: 1,
                            endLine: 2,
                            symbol: "foo",
                            summary: "출처 설명",
                            url: "https://example.com",
                        ),
                        SourceResponseDTO(
                            file: "b.swift",
                            startLine: 10,
                            endLine: 12,
                            symbol: "bar",
                            summary: nil,
                            url: "https://example.com/b",
                        ),
                    ],
                    myAnswer: MyAnswerResponseDTO(
                        selectedIndex: 1,
                        text: nil,
                        correct: true,
                        answeredAt: Date(timeIntervalSince1970: 0),
                    ),
                ),
                QuestionResponseDTO(
                    questionID: "question-2",
                    format: "essay",
                    text: "질문2",
                    choices: [],
                    sources: [],
                    myAnswer: MyAnswerResponseDTO(
                        selectedIndex: nil,
                        text: "작성한 답안",
                        correct: nil,
                        answeredAt: Date(timeIntervalSince1970: 0),
                    ),
                ),
                QuestionResponseDTO(
                    questionID: "question-3",
                    format: "multiple_choice",
                    text: "질문3",
                    choices: ["A", "B"],
                    sources: [],
                    myAnswer: nil,
                ),
            ],
        )
    }

}

// MARK: - StubLearningSetRemote

private struct StubLearningSetRemote: LearningSetRemote {
    let result: Result<LearningSetResponseDTO, DataLearningProjectError>

    func fetchLearningSet(
        projectID _: String,
        setID _: String,
    ) async throws -> LearningSetResponseDTO {
        try result.get()
    }
}
