import Foundation
import Testing
@testable import CompositionAdapter
@testable import DomainAuthentication
@testable import InfrastructureAuthentication

// MARK: - SessionAvailabilityResolverTests

@Suite("SessionAvailabilityResolver")
struct SessionAvailabilityResolverTests {

    // MARK: Internal

    @Test
    func `마커가 없으면 본 앱 실행이 필요하다고 판정한다`() async throws {
        let context = try Context()

        #expect(await context.resolve() == .appLaunchRequired)
    }

    @Test
    func `마커가 로그아웃이면 로그인이 필요하다고 판정한다`() async throws {
        let context = try Context()
        await context.markerCoding.save(isSignedIn: false)

        #expect(await context.resolve() == .signInRequired)
    }

    @Test
    func `마커는 로그인이지만 저장된 세션이 없으면 로그인이 필요하다고 판정한다`() async throws {
        let context = try Context()
        await context.markerCoding.save(isSignedIn: true)

        #expect(await context.resolve() == .signInRequired)
    }

    @Test
    func `접근 토큰이 만료되었으면 갱신하지 않고 로그인이 필요하다고 판정한다`() async throws {
        let context = try Context()
        await context.markerCoding.save(isSignedIn: true)
        try context.saveSession(
            accessToken: "expired-token",
            expiresAt: Context.now.addingTimeInterval(-1),
        )

        #expect(await context.resolve() == .signInRequired)
    }

    @Test
    func `유효한 접근 토큰이 있으면 등록을 진행할 수 있다고 판정한다`() async throws {
        let context = try Context()
        await context.markerCoding.save(isSignedIn: true)
        try context.saveSession(
            accessToken: "valid-token",
            expiresAt: Context.now.addingTimeInterval(60),
        )

        #expect(await context.resolve() == .available(accessToken: "valid-token"))
    }

    @Test
    func `만료 시각이 없으면 서버 판단에 맡기고 사용 가능으로 판정한다`() async throws {
        let context = try Context()
        await context.markerCoding.save(isSignedIn: true)
        try context.saveSession(
            accessToken: "no-expiry-token",
            expiresAt: nil,
        )

        #expect(await context.resolve() == .available(accessToken: "no-expiry-token"))
    }

    // MARK: Private

    private struct Context {

        // MARK: Lifecycle

        init() throws {
            let suiteName = "SessionAvailabilityResolverTests.\(UUID().uuidString)"
            userDefaults = try #require(UserDefaults(suiteName: suiteName))
            self.suiteName = suiteName
            markerCoding = SharedSessionStateMarkerCoding(userDefaults: userDefaults)
            keychainStore = KeychainStore(backend: KeychainStore.InMemoryBackend())
        }

        // MARK: Internal

        static let now = Date(timeIntervalSince1970: 1_700_000_000)

        let userDefaults: UserDefaults
        let suiteName: String
        let markerCoding: SharedSessionStateMarkerCoding
        let keychainStore: KeychainStore

        func saveSession(
            accessToken: String,
            expiresAt: Date?,
        ) throws {
            try SessionRecordKeychainCoding(keychainStore: keychainStore).save(
                SessionRecord(
                    tokens: SessionTokens(
                        accessToken: accessToken,
                        refreshToken: "refresh",
                        accessTokenExpiresAt: expiresAt,
                        refreshTokenExpiresAt: nil,
                    ),
                    onboarding: LocalOnboardingState(
                        needsCuration: false,
                        acceptedLegalVersions: [],
                        acceptedAt: nil,
                    ),
                )
            )
        }

        func resolve() async -> SessionAvailability {
            await SessionAvailabilityResolver(
                markerCoding: markerCoding,
                keychainStore: keychainStore,
                now: { Self.now },
            )()
        }

    }

}
