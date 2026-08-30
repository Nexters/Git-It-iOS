import Foundation
import InfrastructureNetworkClient
import Testing

@testable import DataLearningProject

// MARK: - HTTPBookmarkRemoteTests

@Suite("HTTPBookmarkRemote")
struct HTTPBookmarkRemoteTests {

    @Test
    func `북마크 설정 요청을 bookmark 경로와 원하는 bool 본문으로 구성한다`() async throws {
        let transport = StubHTTPTransport(results: [
            .response(jsonResponse(
                statusCode: 200,
                envelope: #"{"success":true,"data":{"bookmarked":true},"code":null,"message":null,"errors":null}"#,
            ))
        ])
        let remote = makeRemote(transport: transport)

        let state = try await remote.setBookmark(
            projectID: "project-1",
            questionID: "question-1",
            request: BookmarkQuestionRequestDTO(bookmarked: true),
        )

        #expect(state.bookmarked)
        let request = try #require(await transport.recordedRequests.first)
        #expect(request.url.path == "/api/v1/projects/project-1/questions/question-1/bookmark")
        let bodyData = try #require(request.body)
        let body = try #require(JSONSerialization.jsonObject(with: bodyData) as? [String: Bool])
        #expect(body["bookmarked"] == true)
    }

    @Test
    func `projectID 없이 조회하면 쿼리 없이 bookmarks 목록 경로를 사용한다`() async throws {
        let transport = StubHTTPTransport(results: [
            .response(jsonResponse(
                statusCode: 200,
                envelope: #"{"success":true,"data":{"totalCount":0,"availableProjects":[],"bookmarks":[]},"code":null,"message":null,"errors":null}"#,
            ))
        ])
        let remote = makeRemote(transport: transport)

        _ = try await remote.fetchBookmarks(projectID: nil)

        let request = try #require(await transport.recordedRequests.first)
        #expect(request.url.path == "/api/v1/projects/bookmarks")
        #expect(request.url.query == nil)
    }

    @Test
    func `projectID로 필터하면 쿼리에 projectId를 싣는다`() async throws {
        let transport = StubHTTPTransport(results: [
            .response(jsonResponse(
                statusCode: 200,
                envelope: #"{"success":true,"data":{"totalCount":0,"availableProjects":[],"bookmarks":[]},"code":null,"message":null,"errors":null}"#,
            ))
        ])
        let remote = makeRemote(transport: transport)

        _ = try await remote.fetchBookmarks(projectID: "project-1")

        let request = try #require(await transport.recordedRequests.first)
        #expect(request.url.query == "projectId=project-1")
    }

}

extension HTTPBookmarkRemoteTests {
    private func makeRemote(transport: StubHTTPTransport) -> HTTPBookmarkRemote {
        let client = HTTPClient(
            baseURL: URL(string: "https://api.git-it.example.com")!,
            bodyCoding: JSONBodyCoding(),
            transport: transport,
        )
        return HTTPBookmarkRemote(client: client, accessTokenProvider: { "test-access-token" })
    }

    private func jsonResponse(
        statusCode: Int,
        envelope: String,
    ) -> HTTPTransportResponse {
        HTTPTransportResponse(statusCode: statusCode, headers: [:], body: Data(envelope.utf8))
    }
}
