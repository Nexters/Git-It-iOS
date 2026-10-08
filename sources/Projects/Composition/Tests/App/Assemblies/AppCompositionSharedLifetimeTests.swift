import Foundation
import Testing

@testable import CompositionApp
@testable import DataAuthentication
@testable import DataShared

@Suite("AppComposition 공유 세션 수명")
struct AppCompositionSharedLifetimeTests {

    @Test
    func `Project와 UserInfo 보호 Remote가 같은 access token을 사용한다`() async throws {
        let secureStorage = InMemorySecureValueStorage()
        try SessionRecordStorageCoding(storage: secureStorage).save(StoredSessionRecord(
            accessToken: "shared-access-token",
            refreshToken: "refresh-1",
            accessTokenExpiresAt: nil,
            refreshTokenExpiresAt: nil,
            needsCuration: false,
            acceptedLegalVersions: [],
            acceptedAt: nil,
        ))

        let transport = RecordingRequestTransport(results: [
            TransportResponse(
                statusCode: 200,
                body: Data(#"{"success":true,"data":{"items":[],"hasNext":false},"code":null,"message":null,"errors":null}"#
                    .utf8),
            ),
            TransportResponse(
                statusCode: 200,
                body: Data(#"""
                    {"success":true,"data":{"name":"홍길동","email":"a@b.com","position":"BACKEND","careerLevel":"JUNIOR","thisWeekSolvedCount":0,"thisMonthSolvedCount":0,"streakDays":0,"weeklyChart":[]},"code":null,"message":null,"errors":null}
                    """#.utf8),
            ),
        ])

        let composition = AppComposition.live(
            AppComposition.Environment(
                apiBaseURL: try #require(URL(string: "https://api.git-it.example.com")),
                externalRepositoryBaseURL: try #require(URL(string: "https://api.github.com")),
                appVersion: "1.0.0",
                osVersion: "Version 26.0",
            ),
            secureStorage: secureStorage,
            transport: transport,
        )

        try await composition.project.refresh()
        _ = try await composition.userInfo.detail()

        let requests = await transport.recordedRequests
        #expect(requests.count == 2)
        #expect(requests[0].headerFields["authorization"] == "Bearer shared-access-token")
        #expect(requests[1].headerFields["authorization"] == "Bearer shared-access-token")
    }

}
