import DataShared
import Foundation
import Testing

@testable import CompositionAuthentication
@testable import DataAuthentication
@testable import DomainAccount

// MARK: - SignInRepositoryAdapterTests

@Suite("SignInRepositoryAdapter")
struct SignInRepositoryAdapterTests {

    // MARK: Internal

    @Test
    func `로그인을 시작하면 큐레이션 필요 여부를 그대로 전달한다`() async throws {
        let context = try Context(results: [Self.loginResponse(needsCuration: true)])
        try context.saveAppleUserID()

        let record = try await context.adapter.start(with: AuthenticationGrant(id: "id-token", method: .apple))

        #expect(record.account.needsCuration)
        #expect(record.account.id == "apple-user")
        #expect(record.isAccountAvailable)
        #expect(await context.markerCoding.loadSignedInState() == true)
    }

    @Test
    func `로컬 로그아웃은 저장 기록과 공유 표시를 정리한다`() async throws {
        let context = try Context(results: [])
        try context.saveSession(accessTokenExpiresAt: nil)
        await context.markerCoding.save(isSignedIn: true)

        try await context.adapter.signOut()

        #expect(try context.coding.load() == nil)
        #expect(await context.markerCoding.loadSignedInState() == false)
        #expect(await context.adapter.sharedSignInState() == false)
    }

    @Test
    func `만료된 기록은 사용 가능한 인증 정보로 보지 않는다`() async throws {
        let context = try Context(results: [])
        try context.saveSession(accessTokenExpiresAt: Self.now.addingTimeInterval(-1))

        #expect(await context.adapter.hasUsableCredential() == false)
    }

    @Test
    func `유효한 기록이 있으면 사용 가능한 인증 정보로 본다`() async throws {
        let context = try Context(results: [])
        try context.saveSession(accessTokenExpiresAt: Self.now.addingTimeInterval(60))

        #expect(await context.adapter.hasUsableCredential())
    }

    // MARK: Private

    private struct Context {

        // MARK: Lifecycle

        init(results: [TransportResponse]) throws {
            let secureStorage = InMemorySecureValueStorage()
            let sharedStorage = InMemoryKeyValueStorage()
            self.secureStorage = secureStorage
            markerCoding = SharedSessionStateMarkerCoding(storage: sharedStorage)
            coding = SessionRecordStorageCoding(storage: secureStorage)
            let transport = RecordingRequestTransport(results: results)
            adapter = SignInRepositoryAdapter(
                remote: AuthenticationRemote(
                    baseURL: try #require(URL(string: "https://api.git-it.example.com")),
                    transport: transport,
                    responseTimeout: RequestClientFactory.defaultResponseTimeout,
                    credential: { .available("access-token") },
                ),
                sessionStorage: secureStorage,
                appleIdentityStorage: secureStorage,
                requestCredentialProvider: RequestCredentialProvider(
                    secureStorage: secureStorage,
                    now: { SignInRepositoryAdapterTests.now },
                ),
                sharedSessionStateMarkerCoding: markerCoding,
            )
        }

        // MARK: Internal

        let secureStorage: InMemorySecureValueStorage
        let markerCoding: SharedSessionStateMarkerCoding
        let coding: SessionRecordStorageCoding
        let adapter: SignInRepositoryAdapter

        func saveAppleUserID() throws {
            try AppleIdentityStore(storage: secureStorage).save("apple-user")
        }

        func saveSession(accessTokenExpiresAt: Date?) throws {
            try coding.save(StoredSessionRecord(
                accessToken: "access-token",
                refreshToken: "refresh-token",
                accessTokenExpiresAt: accessTokenExpiresAt,
                refreshTokenExpiresAt: nil,
                needsCuration: false,
                acceptedLegalVersions: [],
                acceptedAt: nil,
            ))
        }

    }

    private static let now = Date(timeIntervalSince1970: 1_000)

    private static func loginResponse(needsCuration: Bool) -> TransportResponse {
        let envelope = """
            {"success":true,"data":{"accessToken":"access-token","refreshToken":"refresh-token",\
            "needsCuration":\(needsCuration)},"code":null,"message":null,"errors":null}
            """
        return TransportResponse(statusCode: 200, body: Data(envelope.utf8))
    }

}
