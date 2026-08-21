import Testing

@testable import DataLearningProject

@Suite("AnswerEndpoint 계약")
struct AnswerEndpointTests {

    @Test
    func `객관식 답변은 POST로 choice 경로를 요청한다`() {
        let request = AnswerEndpoint.choice(projectID: "project-1", questionID: "question-1").request

        #expect(request.method == .post)
        #expect(request.path == "/api/v1/projects/project-1/questions/question-1/answers/choice")
    }

    @Test
    func `서술형 답변은 POST로 essay 경로를 요청한다`() {
        let request = AnswerEndpoint.essay(projectID: "project-1", questionID: "question-1").request

        #expect(request.method == .post)
        #expect(request.path == "/api/v1/projects/project-1/questions/question-1/answers/essay")
    }

}
