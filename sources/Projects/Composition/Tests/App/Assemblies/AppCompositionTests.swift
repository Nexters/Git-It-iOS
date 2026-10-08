import DomainUserInfo
import Foundation
import Testing

@testable import CompositionApp
@testable import DataAuthentication
@testable import DataShared

@Suite("AppComposition")
struct AppCompositionTests {

    // MARK: Internal

    @Test
    func `userInfo 큐레이션은 저장된 공유 세션 access token으로 요청한다`() async throws {
        let secureStorage = InMemorySecureValueStorage()
        try SessionRecordStorageCoding(storage: secureStorage).save(StoredSessionRecord(
            accessToken: "shared-access-token",
            refreshToken: "refresh-1",
            accessTokenExpiresAt: nil,
            refreshTokenExpiresAt: nil,
            needsCuration: true,
            acceptedLegalVersions: [],
            acceptedAt: nil,
        ))

        let transport = RecordingRequestTransport(results: [
            TransportResponse(
                statusCode: 200,
                body: Data(#"{"success":true,"data":{},"code":null,"message":null,"errors":null}"#.utf8),
            )
        ])

        let composition = AppComposition.live(
            try Self.environment(),
            secureStorage: secureStorage,
            transport: transport,
        )

        try await composition.userInfo.updateCuration(Curation(
            position: .ios,
            careerLevel: .junior,
        ))

        let requests = await transport.recordedRequests
        #expect(requests.count == 1)
        #expect(requests[0].headerFields["authorization"] == "Bearer shared-access-token")
        #expect(requests[0].url.path == "/api/v1/members/me/curation")
    }

    @Test
    func `userInfo 공개 property는 Domain UseCase Protocol 타입이다`() throws {
        let composition = AppComposition.live(try Self.environment())

        _ = composition.userInfo as any UserInfoUseCase
    }

    // MARK: Private

    private static func environment() throws -> AppComposition.Environment {
        AppComposition.Environment(
            apiBaseURL: try #require(URL(string: "https://api.git-it.example.com")),
            externalRepositoryBaseURL: try #require(URL(string: "https://api.github.com")),
            appVersion: "1.0.0",
            osVersion: "Version 26.0",
        )
    }

}
