import DomainAuthentication
import DomainMember
import Foundation
import Testing

@testable import CompositionAdapter
@testable import InfrastructureAuthentication
@testable import InfrastructureNetworkClient

@Suite("AppComposition")
struct AppCompositionTests {

    @Test
    func `completeCuration은 Member graph와 같은 공유 세션 access token으로 요청한다`() async throws {
        let keychainStore = KeychainStore(backend: KeychainStore.InMemoryBackend())
        try SessionRecordKeychainCoding(keychainStore: keychainStore).save(SessionRecord(
            tokens: SessionTokens(
                accessToken: "shared-access-token",
                refreshToken: "refresh-1",
                accessTokenExpiresAt: nil,
                refreshTokenExpiresAt: nil,
            ),
            onboarding: LocalOnboardingState(needsCuration: true, acceptedLegalVersions: [], acceptedAt: nil),
        ))

        let transport = RecordingHTTPTransport(results: [
            HTTPTransportResponse(
                statusCode: 200,
                headers: [:],
                body: Data(#"{"success":true,"data":{},"code":null,"message":null,"errors":null}"#.utf8),
            )
        ])

        let composition = AppComposition.live(
            AppComposition.Environment(
                apiBaseURL: try #require(URL(string: "https://api.git-it.example.com")),
                externalRepositoryBaseURL: try #require(URL(string: "https://api.github.com")),
            ),
            keychainStore: keychainStore,
            transport: transport,
        )

        try await composition.completeCuration(position: .ios, careerLevel: .junior)

        let requests = await transport.recordedRequests
        #expect(requests.count == 1)
        #expect(requests[0].headers["Authorization"] == "Bearer shared-access-token")
        #expect(requests[0].url.path == "/api/v1/members/me/curation")
    }

    @Test
    func `completeCuration 공개 property는 Domain UseCase Protocol 타입이다`() throws {
        let composition = AppComposition.live(
            AppComposition.Environment(
                apiBaseURL: try #require(URL(string: "https://api.git-it.example.com")),
                externalRepositoryBaseURL: try #require(URL(string: "https://api.github.com")),
            )
        )

        _ = composition.completeCuration as any CompleteCurationUseCase
    }

}
