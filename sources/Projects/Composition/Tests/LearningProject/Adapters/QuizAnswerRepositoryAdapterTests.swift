import Foundation
import Testing

@testable import CompositionLearningProject
@testable import DataLearningProject
@testable import DataShared
@testable import DomainUseCaseInterface

// MARK: - QuizAnswerRepositoryAdapterTests

@Suite("QuizAnswerRepositoryAdapter")
struct QuizAnswerRepositoryAdapterTests {

    // MARK: Internal

    @Test
    func `객관식 응답 DTO를 Domain ChoiceGrading으로 변환한다`() async throws {
        let transport = RecordingRequestTransport(results: [
            Self.successResponse(#"{"questionId":"question-1","correct":true,"answerIndex":1,"explanation":"설명"}"#)
        ])
        let adapter = Self.makeAdapter(transport: transport)

        let grading = try await adapter.submit(ChoiceAnswer(
            projectID: "project-1",
            quizID: "question-1",
            selectedIndex: 1,
        ))

        #expect(grading == ChoiceGrading(
            isCorrect: true,
            correctIndex: 1,
            explanation: "설명",
        ))
        let request = try #require(await transport.recordedRequests.first)
        #expect(request.url.path == "/api/v1/projects/project-1/questions/question-1/answers/choice")
    }

    @Test
    func `서술형 응답 DTO를 Domain EssayGrading으로 변환한다`() async throws {
        let adapter = Self.makeAdapter(transport: RecordingRequestTransport(results: [
            Self.successResponse(#"""
                {"questionId":"question-1","explanation":"설명","rubric":{"criteria":[{"text":"good","points":90}],"keyPoints":[],"fullMarkExample":"","partialExample":"","zeroExample":""}}
                """#)
        ]))

        let grading = try await adapter.submit(EssayAnswer(
            projectID: "project-1",
            quizID: "question-1",
            text: "내 답",
        ))

        #expect(grading == EssayGrading(
            explanation: "설명",
            rubric: ["good"],
        ))
    }

    @Test
    func `Data 오류를 Domain 오류로 변환한다`() async {
        let adapter = Self.makeAdapter(transport: RecordingRequestTransport(results: [
            Self.errorResponse(
                statusCode: 404,
                code: "QUIZ-005",
            )
        ]))

        await #expect(throws: QuizDetailError.quizUnavailable) {
            _ = try await adapter.submit(ChoiceAnswer(
                projectID: "project-1",
                quizID: "missing",
                selectedIndex: 0,
            ))
        }
    }

    // MARK: Private

    private static func makeAdapter(transport: RecordingRequestTransport) -> QuizAnswerRepositoryAdapter {
        QuizAnswerRepositoryAdapter(remote: AnswerRemote(
            baseURL: URL(string: "https://api.git-it.example.com")!,
            transport: transport,
            responseTimeout: RequestClientFactory.defaultResponseTimeout,
            credential: { .available("test-access-token") },
            credentialRejected: { },
        ))
    }

    private static func successResponse(_ payload: String) -> TransportResponse {
        TransportResponse(
            statusCode: 200,
            body: Data(#"{"success":true,"data":\#(payload),"code":null,"message":null,"errors":null}"#.utf8),
        )
    }

    private static func errorResponse(
        statusCode: Int,
        code: String,
    ) -> TransportResponse {
        TransportResponse(
            statusCode: statusCode,
            body: Data(#"{"success":false,"data":null,"code":"\#(code)","message":"error","errors":null}"#.utf8),
        )
    }

}
