import Foundation
import Testing
@testable import CompositionAuthentication
@testable import DataAuthentication
@testable import DataShared

struct AuthenticationAssemblyTests {

    @Test
    func `저장된 세션이 없으면 요청 자격이 signedOut이다`() async throws {
        let assembly = AuthenticationAssembly(
            secureStorage: InMemorySecureValueStorage(),
            sharedStorage: InMemoryKeyValueStorage(),
        )

        #expect(await assembly.requestCredentialProvider.credential() == .signedOut)
    }

    @Test
    func `저장된 세션이 없으면 공유 세션 표시를 로그아웃으로 기록한다`() async throws {
        let sharedStorage = InMemoryKeyValueStorage()
        let assembly = AuthenticationAssembly(
            secureStorage: InMemorySecureValueStorage(),
            sharedStorage: sharedStorage,
        )

        await assembly.recordSharedSessionState()

        #expect(await SharedSessionStateMarkerCoding(storage: sharedStorage).loadSignedInState() == false)
    }

    @Test
    func `저장된 세션이 있으면 공유 세션 표시를 로그인으로 기록한다`() async throws {
        let secureStorage = InMemorySecureValueStorage()
        try SessionRecordStorageCoding(storage: secureStorage).save(StoredSessionRecord(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            accessTokenExpiresAt: nil,
            refreshTokenExpiresAt: nil,
            needsCuration: false,
            acceptedLegalVersions: [],
            acceptedAt: nil,
        ))
        let sharedStorage = InMemoryKeyValueStorage()
        let assembly = AuthenticationAssembly(
            secureStorage: secureStorage,
            sharedStorage: sharedStorage,
        )

        await assembly.recordSharedSessionState()

        #expect(await SharedSessionStateMarkerCoding(storage: sharedStorage).loadSignedInState() == true)
    }

}
