import Testing

@testable import DataLearningProject

@Suite("BookmarkEndpoint 계약")
struct BookmarkEndpointTests {

    @Test
    func `북마크 설정은 POST로 질문 경로를 요청한다`() {
        let request = BookmarkEndpoint.set(projectID: "project-1", questionID: "question-1").request

        #expect(request.method == .post)
        #expect(request.path == "/api/v1/projects/project-1/questions/question-1/bookmark")
    }

    @Test
    func `북마크 목록은 projectId가 없으면 쿼리를 비운다`() {
        let request = BookmarkEndpoint.list(projectID: nil).request

        #expect(request.method == .get)
        #expect(request.path == "/api/v1/projects/bookmarks")
        #expect(request.queryItems["projectId"] == nil)
    }

    @Test
    func `북마크 목록은 projectId가 있으면 쿼리에 포함한다`() {
        let request = BookmarkEndpoint.list(projectID: "project-1").request

        #expect(request.queryItems["projectId"] == "project-1")
    }

}
