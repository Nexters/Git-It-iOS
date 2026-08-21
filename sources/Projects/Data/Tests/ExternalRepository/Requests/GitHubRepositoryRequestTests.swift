import Testing

@testable import DataExternalRepository

@Suite("GitHub Repository 요청")
struct GitHubRepositoryRequestTests {
    @Test
    func `공개 Repository endpoint와 필수 헤더를 고정한다`() {
        let request = GitHubRepositoryRequest(owner: "facebook", repository: "react")

        #expect(request.scheme == "https")
        #expect(request.host == "api.github.com")
        #expect(request.method == "GET")
        #expect(request.path == "/repos/facebook/react")
        #expect(request.headers == [
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
        ])
    }

    @Test
    func `Authorization과 Git It 및 Apple credential을 포함하지 않는다`() {
        let request = GitHubRepositoryRequest(owner: "facebook", repository: "react")
        let serializedHeaders = request.headers.description.lowercased()

        #expect(request.headers["Authorization"] == nil)
        #expect(!serializedHeaders.contains("access token"))
        #expect(!serializedHeaders.contains("refresh token"))
        #expect(!serializedHeaders.contains("identity token"))
    }
}
