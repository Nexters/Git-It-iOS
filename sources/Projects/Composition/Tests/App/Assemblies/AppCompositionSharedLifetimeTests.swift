import DomainAuthentication
import DomainLearningProject
import Foundation
import Testing

@testable import CompositionAdapter
@testable import CompositionApp
@testable import InfrastructureAuthentication
@testable import InfrastructureNetworkClient

@Suite("AppComposition 공유 세션 수명")
struct AppCompositionSharedLifetimeTests {

    @Test
    func `LearningProject와 Member 보호 Remote가 같은 access token을 사용한다`() async throws {
        let keychainStore = KeychainStore(backend: KeychainStore.InMemoryBackend())
        try SessionRecordKeychainCoding(keychainStore: keychainStore).save(SessionRecord(
            tokens: SessionTokens(
                accessToken: "shared-access-token",
                refreshToken: "refresh-1",
                accessTokenExpiresAt: nil,
                refreshTokenExpiresAt: nil,
            ),
            onboarding: LocalOnboardingState(needsCuration: false, acceptedLegalVersions: [], acceptedAt: nil),
        ))

        let transport = RecordingHTTPTransport(results: [
            HTTPTransportResponse(
                statusCode: 200,
                headers: [:],
                body: Data(#"{"success":true,"data":{"items":[],"hasNext":false},"code":null,"message":null,"errors":null}"#
                    .utf8),
            ),
            HTTPTransportResponse(
                statusCode: 200,
                headers: [:],
                body: Data(#"""
                    {"success":true,"data":{"name":"홍길동","email":"a@b.com","position":"BACKEND","careerLevel":"JUNIOR","thisWeekSolvedCount":0,"thisMonthSolvedCount":0,"streakDays":0,"weeklyChart":[]},"code":null,"message":null,"errors":null}
                    """#.utf8),
            ),
        ])

        let composition = AppComposition.live(
            AppComposition.Environment(
                apiBaseURL: try #require(URL(string: "https://api.git-it.example.com")),
                externalRepositoryBaseURL: try #require(URL(string: "https://api.github.com")),
            ),
            keychainStore: keychainStore,
            transport: transport,
        )

        _ = try await composition.fetchLearningProjects(page: LearningProjectPage.firstIndex)
        _ = try await composition.fetchMemberProfile()

        let requests = await transport.recordedRequests
        #expect(requests.count == 2)
        #expect(requests[0].headers["Authorization"] == "Bearer shared-access-token")
        #expect(requests[1].headers["Authorization"] == "Bearer shared-access-token")
    }

}
