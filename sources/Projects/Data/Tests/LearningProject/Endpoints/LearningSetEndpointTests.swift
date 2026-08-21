import Testing

@testable import DataLearningProject

@Suite("LearningSetEndpoint 계약")
struct LearningSetEndpointTests {

    @Test
    func `학습 세트는 GET으로 프로젝트와 세트 식별자 경로를 요청한다`() {
        let request = LearningSetEndpoint.detail(projectID: "project-1", setID: "set-1").request

        #expect(request.method == .get)
        #expect(request.path == "/api/v1/projects/project-1/sets/set-1")
        #expect(request.queryItems.isEmpty)
    }

}
