import Foundation
import Testing

@testable import CompositionLearningProject
@testable import DataLearningProject
@testable import DataShared
@testable import DomainQuizDetail

// MARK: - QuizSetRepositoryAdapterTests

@Suite("QuizSetRepositoryAdapter")
struct QuizSetRepositoryAdapterTests {

    // MARK: Internal

    @Test
    func `DTO를 Domain QuizSet으로 서버 순서 그대로 변환한다`() async throws {
        let quizSet = try await Self.fetchQuizSet(payload: #"""
            {"setId":"set-1","title":"제목","description":"설명","orientation":"front","level":"L1","questions":[\#
            {"questionId":"question-1","format":"multiple_choice","text":"질문","choices":["A","B"],"sources":[\#
            {"file":"a.swift","startLine":1,"endLine":2,"symbol":"foo","summary":null,"url":"https://example.com"}],\#
            "myAnswer":null},\#
            {"questionId":"question-2","format":"essay","text":"질문2","choices":[],"sources":[],"myAnswer":null}]}
            """#)

        #expect(quizSet.id == "set-1")
        #expect(quizSet.title == "제목")
        #expect(quizSet.quizzes.map(\.id) == ["question-1", "question-2"])
        #expect(quizSet.quizzes[0].prompt == "질문")
        #expect(quizSet.quizzes[0].content == .choice(
            options: ["A", "B"],
            submitted: nil,
        ))
        #expect(quizSet.quizzes[1].content == .essay(submitted: nil))
    }

    @Test
    func `세트 설명을 복원한다`() async throws {
        let quizSet = try await Self.fetchQuizSet(payload: Self.fixturePayload)

        #expect(quizSet.description == "세트 설명")
    }

    @Test
    func `출처 배열 전체를 순서대로 복원한다`() async throws {
        let quizSet = try await Self.fetchQuizSet(payload: Self.fixturePayload)

        #expect(quizSet.quizzes[0].sources.count == 2)
        #expect(quizSet.quizzes[0].sources.map(\.filePath) == ["a.swift", "b.swift"])
        #expect(quizSet.quizzes[1].sources.isEmpty)
    }

    @Test
    func `각 출처의 줄 번호와 심볼과 설명을 복원한다`() async throws {
        let quizSet = try await Self.fetchQuizSet(payload: Self.fixturePayload)
        let source = try #require(quizSet.quizzes[0].sources.first)

        #expect(source == QuizSource(
            filePath: "a.swift",
            startLine: 1,
            endLine: 2,
            symbol: "foo",
            summary: "출처 설명",
            referenceURL: "https://example.com",
        ))
    }

    @Test
    func `객관식 기존 답변의 선택 index와 정답 여부를 복원한다`() async throws {
        let quizSet = try await Self.fetchQuizSet(payload: Self.fixturePayload)

        #expect(quizSet.quizzes[0].content == .choice(
            options: ["A", "B", "C"],
            submitted: ChoiceSubmission(
                selectedIndex: 1,
                isCorrect: true,
            ),
        ))
    }

    @Test
    func `서술형 기존 답변의 텍스트를 복원한다`() async throws {
        let quizSet = try await Self.fetchQuizSet(payload: Self.fixturePayload)

        #expect(quizSet.quizzes[1].content == .essay(submitted: EssaySubmission(text: "작성한 답안")))
    }

    @Test
    func `기존 답변이 없는 문제는 제출 기록을 비운다`() async throws {
        let quizSet = try await Self.fetchQuizSet(payload: Self.fixturePayload)

        #expect(quizSet.quizzes[2].content == .choice(
            options: ["A", "B"],
            submitted: nil,
        ))
    }

    @Test
    func `객관식 기존 답변에 정답 여부가 없으면 제출 기록을 비운다`() async throws {
        let quizSet = try await Self.fetchQuizSet(payload: #"""
            {"setId":"set-1","title":"제목","description":"설명","orientation":"front","level":"L1","questions":[\#
            {"questionId":"question-1","format":"multiple_choice","text":"질문","choices":["A","B"],"sources":[],\#
            "myAnswer":{"selectedIndex":1,"text":null,"correct":null,"answeredAt":"1970-01-01T00:00:00Z"}}]}
            """#)

        #expect(quizSet.quizzes[0].content == .choice(
            options: ["A", "B"],
            submitted: nil,
        ))
    }

    @Test
    func `문제 배열의 서버 순서를 재정렬하지 않는다`() async throws {
        let quizSet = try await Self.fetchQuizSet(payload: Self.fixturePayload)

        #expect(quizSet.quizzes.map(\.id) == ["question-1", "question-2", "question-3"])
    }

    @Test
    func `Data 오류를 Domain 오류로 변환한다`() async {
        let adapter = Self.makeAdapter(results: [
            TransportResponse(
                statusCode: 404,
                body: Data(#"{"success":false,"data":null,"code":"QUIZ-006","message":"error","errors":null}"#.utf8),
            )
        ])

        await #expect(throws: QuizDetailError.quizSetUnavailable) {
            _ = try await adapter.quizSet(
                "missing",
                in: "project-1",
            )
        }
    }

    // MARK: Private

    private static let fixturePayload = #"""
        {"setId":"set-1","title":"제목","description":"세트 설명","orientation":"front","level":"L1","questions":[\#
        {"questionId":"question-1","format":"multiple_choice","text":"질문","choices":["A","B","C"],"sources":[\#
        {"file":"a.swift","startLine":1,"endLine":2,"symbol":"foo","summary":"출처 설명","url":"https://example.com"},\#
        {"file":"b.swift","startLine":10,"endLine":12,"symbol":"bar","summary":null,"url":"https://example.com/b"}],\#
        "myAnswer":{"selectedIndex":1,"text":null,"correct":true,"answeredAt":"1970-01-01T00:00:00Z"}},\#
        {"questionId":"question-2","format":"essay","text":"질문2","choices":[],"sources":[],\#
        "myAnswer":{"selectedIndex":null,"text":"작성한 답안","correct":null,"answeredAt":"1970-01-01T00:00:00Z"}},\#
        {"questionId":"question-3","format":"multiple_choice","text":"질문3","choices":["A","B"],"sources":[],\#
        "myAnswer":null}]}
        """#

    private static func fetchQuizSet(payload: String) async throws -> QuizSet {
        let adapter = makeAdapter(results: [
            TransportResponse(
                statusCode: 200,
                body: Data(#"{"success":true,"data":\#(payload),"code":null,"message":null,"errors":null}"#.utf8),
            )
        ])
        return try await adapter.quizSet(
            "set-1",
            in: "project-1",
        )
    }

    private static func makeAdapter(results: [TransportResponse]) -> QuizSetRepositoryAdapter {
        QuizSetRepositoryAdapter(remote: LearningSetRemote(
            baseURL: URL(string: "https://api.git-it.example.com")!,
            transport: RecordingRequestTransport(results: results),
            responseTimeout: RequestClientFactory.defaultResponseTimeout,
            credential: { .available("test-access-token") },
            credentialRejected: { },
        ))
    }

}
