import Foundation
import Testing

@testable import CompositionAdepter
@testable import DataLearningProject
@testable import InfrastructureNetworkClient

// MARK: - ExternalRepositoryRemoteAdapterTests

@Suite("ExternalRepositoryRemoteAdapter")
struct ExternalRepositoryRemoteAdapterTests {
    @Test
    func `성공 응답을 GitHubRepositoryResponseDTO로 정확히 디코딩한다`() async throws {
        let json = """
            {
                "full_name": "Nexters/Git-it-Server",
                "html_url": "https://github.com/Nexters/Git-it-Server",
                "owner": { "avatar_url": "https://avatars.githubusercontent.com/u/1" },
                "stargazers_count": 42,
                "language": "Kotlin",
                "topics": ["kotlin", "spring-boot"]
            }
            """
        let transport = FakeHTTPTransport(.response(
            HTTPTransportResponse(statusCode: 200, headers: [:], body: Data(json.utf8))
        ))
        let adapter = ExternalRepositoryRemoteAdapter(httpClient: makeHTTPClient(transport: transport))

        let dto = try await adapter.repository(owner: "Nexters", name: "Git-it-Server")

        #expect(dto.fullName == "Nexters/Git-it-Server")
        #expect(dto.htmlURL == "https://github.com/Nexters/Git-it-Server")
        #expect(dto.starCount == 42)
    }

    @Test(arguments: [404, 403, 500])
    func `2xx가 아닌 상태 코드는 other로 매핑된다`(statusCode: Int) async throws {
        let transport = FakeHTTPTransport(.response(
            HTTPTransportResponse(statusCode: statusCode, headers: [:], body: Data())
        ))
        let adapter = ExternalRepositoryRemoteAdapter(httpClient: makeHTTPClient(transport: transport))

        await #expect(throws: DataExternalRepositoryError.other) {
            try await adapter.repository(owner: "owner", name: "repo")
        }
    }

    @Test
    func `연결 실패는 offline으로 매핑된다`() async throws {
        let transport = FakeHTTPTransport(.failure(.connectionFailed))
        let adapter = ExternalRepositoryRemoteAdapter(httpClient: makeHTTPClient(transport: transport))

        await #expect(throws: DataExternalRepositoryError.offline) {
            try await adapter.repository(owner: "owner", name: "repo")
        }
    }

    @Test(arguments: [HTTPClientError.timedOut, .cancelled, .responseDecodingFailed])
    func `그 밖의 HTTPClientError는 other로 매핑된다`(error: HTTPClientError) async throws {
        let transport = FakeHTTPTransport(.failure(error))
        let adapter = ExternalRepositoryRemoteAdapter(httpClient: makeHTTPClient(transport: transport))

        await #expect(throws: DataExternalRepositoryError.other) {
            try await adapter.repository(owner: "owner", name: "repo")
        }
    }

    @Test
    func `요청 URL이 GitHub 공개 API 경로와 일치한다`() async throws {
        let transport = FakeHTTPTransport(.response(
            HTTPTransportResponse(statusCode: 200, headers: [:], body: Data(minimalGitHubJSON.utf8))
        ))
        let adapter = ExternalRepositoryRemoteAdapter(httpClient: makeHTTPClient(transport: transport))

        _ = try await adapter.repository(owner: "owner", name: "repo")

        let recordedURL = await transport.lastRequest?.url
        #expect(recordedURL?.absoluteString == "https://api.github.com/repos/owner/repo")
    }
}

extension ExternalRepositoryRemoteAdapterTests {
    private var minimalGitHubJSON: String {
        """
        {
            "full_name": "owner/repo",
            "html_url": "https://github.com/owner/repo",
            "owner": { "avatar_url": null },
            "stargazers_count": 0,
            "language": null,
            "topics": []
        }
        """
    }

    private func makeHTTPClient(transport: FakeHTTPTransport) -> HTTPClient {
        HTTPClient(
            baseURL: URL(string: "https://api.github.com")!,
            bodyCoding: JSONHTTPBodyCoding(),
            transport: transport,
        )
    }
}

// MARK: - JSONHTTPBodyCoding

struct JSONHTTPBodyCoding: HTTPBodyCoding {
    func encode(_ body: some Encodable) throws -> Data {
        try JSONEncoder().encode(body)
    }

    func decode<Body: Decodable>(
        _: Body.Type,
        from data: Data,
    ) throws -> Body {
        try JSONDecoder().decode(Body.self, from: data)
    }
}

// MARK: - FakeHTTPTransport

actor FakeHTTPTransport: HTTPTransport {

    // MARK: Lifecycle

    init(_ behavior: Behavior) {
        self.behavior = behavior
    }

    // MARK: Internal

    enum Behavior: Sendable {
        case response(HTTPTransportResponse)
        case failure(HTTPClientError)
    }

    private(set) var lastRequest: HTTPTransportRequest?

    func send(_ request: HTTPTransportRequest) async throws(HTTPClientError) -> HTTPTransportResponse {
        lastRequest = request

        switch behavior {
        case .response(let response):
            return response

        case .failure(let error):
            throw error
        }
    }

    // MARK: Private

    private let behavior: Behavior

}
