import Foundation
import Testing
@testable import DomainAuthentication

// MARK: - ResolveSessionAvailabilityTests

@Suite("ResolveSessionAvailability")
struct ResolveSessionAvailabilityTests {

    // MARK: Internal

    @Test
    func `마커가 없으면 앱을 한 번 실행해야 한다고 판정한다`() async {
        let resolve = Self.make(signedInState: nil, session: nil)

        #expect(await resolve() == .appLaunchRequired)
    }

    @Test
    func `마커가 미로그인이면 로그인이 필요하다고 판정한다`() async {
        let resolve = Self.make(signedInState: false, session: Self.record(accessToken: "token"))

        #expect(await resolve() == .signInRequired)
    }

    @Test
    func `로그인 마커가 있어도 저장된 세션이 없으면 로그인이 필요하다고 판정한다`() async {
        let resolve = Self.make(signedInState: true, session: nil)

        #expect(await resolve() == .signInRequired)
    }

    @Test
    func `access token이 비어 있으면 로그인이 필요하다고 판정한다`() async {
        let resolve = Self.make(signedInState: true, session: Self.record(accessToken: ""))

        #expect(await resolve() == .signInRequired)
    }

    @Test
    func `access token 만료 시각이 지났으면 로그인이 필요하다고 판정한다`() async {
        let now = Date(timeIntervalSince1970: 1_000)
        let resolve = Self.make(
            signedInState: true,
            session: Self.record(accessToken: "token", expiresAt: now),
            now: now,
        )

        #expect(await resolve() == .signInRequired)
    }

    @Test
    func `만료되지 않은 세션은 access token과 함께 사용 가능하다고 판정한다`() async {
        let now = Date(timeIntervalSince1970: 1_000)
        let resolve = Self.make(
            signedInState: true,
            session: Self.record(accessToken: "token", expiresAt: now.addingTimeInterval(1)),
            now: now,
        )

        #expect(await resolve() == .available(accessToken: "token"))
    }

    // MARK: Private

    private struct StubMarkerRepository: SharedSessionMarkerRepository {
        let state: Bool?

        func signedInState() async -> Bool? {
            state
        }
    }

    private struct StubSessionRepository: StoredSessionRepository {
        let session: SessionRecord?

        func currentSession() async -> SessionRecord? {
            session
        }
    }

    private static func make(
        signedInState: Bool?,
        session: SessionRecord?,
        now: Date = Date(timeIntervalSince1970: 0),
    ) -> ResolveSessionAvailability {
        ResolveSessionAvailability(
            markerRepository: StubMarkerRepository(state: signedInState),
            sessionRepository: StubSessionRepository(session: session),
            now: { now },
        )
    }

    private static func record(
        accessToken: String,
        expiresAt: Date? = nil,
    ) -> SessionRecord {
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
    }

}
