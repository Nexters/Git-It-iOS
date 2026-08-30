import Foundation
import InfrastructureNetworkClient
import Testing

@testable import DataLearningProject

// MARK: - HTTPAnswerRemoteTests

@Suite("HTTPAnswerRemote")
struct HTTPAnswerRemoteTests {

    @Test
    func `객관식 제출 요청을 answers choice 경로와 selectedIndex 본문으로 구성한다`() async throws {
        let transport = StubHTTPTransport(results: [
            .response(jsonResponse(
                statusCode: 200,
                envelope: #"""
                    {"success":true,"data":{"questionId":"question-1","correct":true,"answerIndex":2,"explanation":"설명"},"code":null,"message":null,"errors":null}
                    """#,
            ))
        ])
        let remote = makeRemote(transport: transport)

        let result = try await remote.submitChoiceAnswer(
            projectID: "project-1",
            questionID: "question-1",
            request: SubmitChoiceAnswerRequestDTO(selectedIndex: 2),
        )

        #expect(result.correct)
        let request = try #require(await transport.recordedRequests.first)
        #expect(request.url.path == "/api/v1/projects/project-1/questions/question-1/answers/choice")
        #expect(request.headers["Authorization"] == "Bearer test-access-token")
        let bodyData = try #require(request.body)
        let body = try #require(JSONSerialization.jsonObject(with: bodyData) as? [String: Int])
        #expect(body["selectedIndex"] == 2)
    }

    @Test
    func `서술형 제출 요청을 answers essay 경로와 text 본문으로 구성한다`() async throws {
        let transport = StubHTTPTransport(results: [
            .response(jsonResponse(
                statusCode: 200,
                envelope: #"""
                    {"success":true,"data":{"questionId":"question-1","explanation":"설명","rubric":{"criteria":[{"text":"good","points":80}],"keyPoints":["핵심 포인트"],"fullMarkExample":"만점 예시","partialExample":"부분 점수 예시","zeroExample":"0점 예시"}},"code":null,"message":null,"errors":null}
                    """#,
            ))
        ])
        let remote = makeRemote(transport: transport)

        let result = try await remote.submitEssayAnswer(
            projectID: "project-1",
            questionID: "question-1",
            request: SubmitEssayAnswerRequestDTO(text: "내 답"),
        )

        #expect(result.rubric.criteria == [RubricCriterionResponseDTO(text: "good", points: 80)])
        #expect(result.rubric.keyPoints == ["핵심 포인트"])
        let request = try #require(await transport.recordedRequests.first)
        #expect(request.url.path == "/api/v1/projects/project-1/questions/question-1/answers/essay")
    }

}

extension HTTPAnswerRemoteTests {
    private func makeRemote(transport: StubHTTPTransport) -> HTTPAnswerRemote {
        let client = HTTPClient(
            baseURL: URL(string: "https://api.git-it.example.com")!,
            bodyCoding: JSONBodyCoding(),
            transport: transport,
        )
        return HTTPAnswerRemote(client: client, accessTokenProvider: { "test-access-token" })
    }

    private func jsonResponse(
        statusCode: Int,
        envelope: String,
    ) -> HTTPTransportResponse {
        HTTPTransportResponse(statusCode: statusCode, headers: [:], body: Data(envelope.utf8))
    }
}
