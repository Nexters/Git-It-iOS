import Foundation
import Testing

@testable import CompositionLearningProject
@testable import DataExternalRepository
@testable import DataShared
@testable import DomainExternalRepository

// MARK: - ExternalRepositoryLookupAdapterTests

@Suite("ExternalRepositoryLookupAdapter")
struct ExternalRepositoryLookupAdapterTests {

    // MARK: Internal

    @Test
    func `GitHub 응답 DTO를 Domain 모델로 변환한다`() async throws {
        let transport = RecordingRequestTransport(results: [
            TransportResponse(
                statusCode: 200,
                body: Data(#"""
                    {"html_url":"https://github.com/facebook/react","name":"react","owner":{"login":"facebook","avatar_url":"https://avatar"},"stargazers_count":10,"topics":["swift"]}
                    """#.utf8),
            )
        ])
        let adapter = ExternalRepositoryLookupAdapter(remote: Self.makeRemote(transport: transport))

        let repository = try await adapter.repository(owner: "facebook", name: "react")

        #expect(repository.canonicalURL == "https://github.com/facebook/react")
        #expect(repository.ownerName == "facebook")
        #expect(repository.repositoryName == "react")
        #expect(repository.imageURL == "https://avatar")
        #expect(repository.starCount == 10)
        #expect(repository.techStack == ["swift"])
        let request = await transport.recordedRequests.first
        #expect(request?.url.path == "/repos/facebook/react")
    }

    @Test
    func `Data 오류를 Domain 오류로 변환한다`() async {
        let adapter = ExternalRepositoryLookupAdapter(
            remote: Self.makeRemote(transport: RecordingRequestTransport(results: []))
        )

        await #expect(throws: ExternalRepositoryError.offline) {
            _ = try await adapter.repository(owner: "facebook", name: "react")
        }
    }

    // MARK: Private

    private static func makeRemote(transport: RecordingRequestTransport) -> ExternalRepositoryRemote {
        ExternalRepositoryRemote(
            baseURL: URL(string: "https://api.github.com")!,
            transport: transport,
            responseTimeout: RequestClientFactory.defaultResponseTimeout,
        )
    }

}
