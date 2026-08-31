import Foundation
import InfrastructureNetworkClient
import Testing

@testable import DataExternalRepository

@Suite("HTTPExternalRepositoryRemote Git-It 인증 미포함 회귀")
struct HTTPExternalRepositoryRemoteNoAuthorizationTests {

    @Test
    func `GitHub 저장소 요청에는 Git-It Bearer token이 포함되지 않는다`() async throws {
        let transport = StubHTTPTransport(results: [
            .response(HTTPTransportResponse(
                statusCode: 200,
                headers: [:],
                body: Data(
                    #"{"html_url":"https://github.com/owner/repo","name":"repo","stargazers_count":0,"topics":[],"owner":{"login":"owner","avatar_url":"https://example.com/a.png"}}"#
                        .utf8
                ),
            ))
        ])
        let client = HTTPClient(
            baseURL: try #require(URL(string: "https://api.github.com")),
            bodyCoding: JSONBodyCoding(),
            transport: transport,
        )
        let remote = HTTPExternalRepositoryRemote(client: client)

        _ = try await remote.repository(GitHubRepositoryRequest(owner: "owner", repository: "repo"))

        let request = try #require(await transport.recordedRequests.first)
        #expect(request.headers["Authorization"] == nil)
        #expect(request.headers.names == ["accept", "x-github-api-version"])
    }

}
