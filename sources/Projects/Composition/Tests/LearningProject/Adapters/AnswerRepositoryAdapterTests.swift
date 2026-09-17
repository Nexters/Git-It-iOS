import Foundation
import Testing

@testable import CompositionLearningProject
@testable import DataLearningProject
@testable import DataShared
@testable import DomainLearningProject

// MARK: - AnswerRepositoryAdapterTests

@Suite("AnswerRepositoryAdapter")
struct AnswerRepositoryAdapterTests {

    // MARK: Internal

    @Test
    func `객관식 응답 DTO를 Domain ChoiceAnswerResult로 변환한다`() async throws {
        let transport = RecordingRequestTransport(results: [
            successResponse(#"{"questionId":"question-1","correct":true,"answerIndex":1,"explanation":"설명"}"#)
        ])
        let adapter = makeAdapter(transport: transport)

        let result = try await adapter.submitChoiceAnswer(
            projectID: "project-1",
            questionID: "question-1",
            selectedIndex: 1,
        )

        #expect(result.correct)
        #expect(result.answerIndex == 1)
        let request = try #require(await transport.recordedRequests.first)
        #expect(request.url.path == "/api/v1/projects/project-1/questions/question-1/answers/choice")
    }

    @Test
    func `서술형 응답 DTO를 Domain EssayAnswerResult로 변환한다`() async throws {
        let adapter = makeAdapter(transport: RecordingRequestTransport(results: [
            successResponse(#"""
                {"questionId":"question-1","explanation":"설명","rubric":{"criteria":[{"text":"good","points":90}],"keyPoints":[],"fullMarkExample":"","partialExample":"","zeroExample":""}}
                """#)
        ]))

        let result = try await adapter.submitEssayAnswer(
            projectID: "project-1",
            questionID: "question-1",
            text: "내 답",
        )

        #expect(result.rubric.criteria == ["good"])
    }

    @Test
    func `Data 오류를 Domain 오류로 변환한다`() async throws {
        let adapter = makeAdapter(transport: RecordingRequestTransport(results: [
            errorResponse(statusCode: 404, code: "QUIZ-005")
        ]))

        await #expect(throws: LearningProjectError.questionUnavailable) {
            try await adapter.submitChoiceAnswer(projectID: "project-1", questionID: "missing", selectedIndex: 0)
        }
    }

    // MARK: Private

    private func makeAdapter(transport: RecordingRequestTransport) -> AnswerRepositoryAdapter {
        AnswerRepositoryAdapter(remote: AnswerRemote(
            baseURL: URL(string: "https://api.git-it.example.com")!,
            transport: transport,
            responseTimeout: RequestClientFactory.defaultResponseTimeout,
            credential: { .available("test-access-token") },
            credentialRejected: { },
        ))
    }

    private func successResponse(_ payload: String) -> TransportResponse {
        TransportResponse(
            statusCode: 200,
            body: Data(#"{"success":true,"data":\#(payload),"code":null,"message":null,"errors":null}"#.utf8),
        )
    }

    private func errorResponse(
        statusCode: Int,
        code: String,
    ) -> TransportResponse {
        TransportResponse(
            statusCode: statusCode,
            body: Data(#"{"success":false,"data":null,"code":"\#(code)","message":"error","errors":null}"#.utf8),
        )
    }

}
