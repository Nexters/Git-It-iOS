import Testing

@testable import DataLearningProject

@Suite("QuizGenerationEndpoint 계약")
struct QuizGenerationEndpointTests {

    @Test
    func `생성 상태는 GET으로 요청한다`() {
        let request = QuizGenerationEndpoint.status(projectID: "project-1").request

        #expect(request.method == .get)
        #expect(request.path == "/api/v1/projects/project-1/status")
    }

    @Test
    func `생성 재시도는 POST로 요청한다`() {
        let request = QuizGenerationEndpoint.retry(projectID: "project-1").request

        #expect(request.method == .post)
        #expect(request.path == "/api/v1/projects/project-1/quiz-generation/retry")
    }

}
