import Testing

@testable import DataLearningProject

@Suite("ProjectEndpoint 계약")
struct ProjectEndpointTests {

    @Test
    func `프로젝트 등록은 POST로 요청한다`() {
        let request = ProjectEndpoint.register.request

        #expect(request.method == .post)
        #expect(request.path == "/api/v1/projects")
        #expect(request.queryItems.isEmpty)
    }

    @Test
    func `프로젝트 목록은 page와 size 쿼리를 포함한다`() {
        let request = ProjectEndpoint.list(page: 2, size: 10).request

        #expect(request.method == .get)
        #expect(request.path == "/api/v1/projects")
        #expect(request.queryItems["page"] == "2")
        #expect(request.queryItems["size"] == "10")
    }

    @Test
    func `프로젝트 상세는 GET으로 식별자 경로를 요청한다`() {
        let request = ProjectEndpoint.detail(projectID: "project-1").request

        #expect(request.method == .get)
        #expect(request.path == "/api/v1/projects/project-1")
    }

    @Test
    func `프로젝트 삭제는 DELETE로 식별자 경로를 요청한다`() {
        let request = ProjectEndpoint.delete(projectID: "project-1").request

        #expect(request.method == .delete)
        #expect(request.path == "/api/v1/projects/project-1")
    }

}
