import Foundation
import InfrastructureNetworkClient
import Testing

@testable import DataExternalRepository

// MARK: - HTTPExternalRepositoryRemoteTests

@Suite("HTTPExternalRepositoryRemote")
struct HTTPExternalRepositoryRemoteTests {

    @Test
    func `GitHub Repository 요청 경로와 헤더를 그대로 전달한다`() async throws {
        let transport = StubHTTPTransport(results: [
            .response(HTTPTransportResponse(
                statusCode: 200,
                headers: [:],
                body: Data(#"""
                    {"html_url":"https://github.com/facebook/react","owner":{"avatar_url":"https://avatar"},"stargazers_count":10,"topics":["swift"]}
                    """#.utf8),
            ))
        ])
        let remote = makeRemote(transport: transport)

        let repository = try await remote.repository(GitHubRepositoryRequest(owner: "facebook", repository: "react"))

        #expect(repository.htmlURL == "https://github.com/facebook/react")
        #expect(repository.starCount == 10)
        let request = await transport.recordedRequests.first
        #expect(request?.url.path == "/repos/facebook/react")
        #expect(request?.headers["Accept"] == "application/vnd.github+json")
    }

    @Test
    func `오프라인 상태를 offline 오류로 변환한다`() async throws {
        let transport = StubHTTPTransport(results: [.failure(.connectionFailed)])
        let remote = makeRemote(transport: transport)

        await #expect(throws: DataExternalRepositoryError.offline) {
            try await remote.repository(GitHubRepositoryRequest(owner: "facebook", repository: "react"))
        }
    }

    @Test
    func `그 외 실패를 other 오류로 변환한다`() async throws {
        let transport = StubHTTPTransport(results: [
            .response(HTTPTransportResponse(statusCode: 404, headers: [:], body: Data()))
        ])
        let remote = makeRemote(transport: transport)

        await #expect(throws: DataExternalRepositoryError.other) {
            try await remote.repository(GitHubRepositoryRequest(owner: "facebook", repository: "react"))
        }
    }

    @Test
    func `취소를 CancellationError로 그대로 전달한다`() async throws {
        let transport = StubHTTPTransport(results: [.failure(.cancelled)])
        let remote = makeRemote(transport: transport)

        await #expect(throws: CancellationError.self) {
            try await remote.repository(GitHubRepositoryRequest(owner: "facebook", repository: "react"))
        }
    }

}

extension HTTPExternalRepositoryRemoteTests {
    private func makeRemote(transport: StubHTTPTransport) -> HTTPExternalRepositoryRemote {
        let client = HTTPClient(
            baseURL: URL(string: "https://api.github.com")!,
            bodyCoding: JSONBodyCoding(),
            transport: transport,
        )
        return HTTPExternalRepositoryRemote(client: client)
    }
}
