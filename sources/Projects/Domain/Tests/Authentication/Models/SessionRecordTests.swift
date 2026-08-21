import Testing

@testable import DomainAuthentication

// MARK: - SessionRecordTests

@Suite("SessionRecord")
struct SessionRecordTests {
    @Test
    func `token pair와 온보딩 상태를 손실 없이 보존한다`() {
        let tokens = SessionTokens(
            accessToken: "access",
            refreshToken: "refresh",
            accessTokenExpiresAt: nil,
            refreshTokenExpiresAt: nil,
        )
        let onboarding = LocalOnboardingState(
            needsCuration: true,
            acceptedLegalVersions: ["v1"],
            acceptedAt: nil,
        )

        let record = SessionRecord(tokens: tokens, onboarding: onboarding)

        #expect(record.tokens == tokens)
        #expect(record.onboarding == onboarding)
        #expect(record.onboarding.needsCuration == true)
    }

    @Test
    func `서버가 만료 시각을 제공하지 않으면 nil을 그대로 유지한다`() {
        let tokens = SessionTokens(
            accessToken: "access",
            refreshToken: "refresh",
            accessTokenExpiresAt: nil,
            refreshTokenExpiresAt: nil,
        )

        #expect(tokens.accessTokenExpiresAt == nil)
        #expect(tokens.refreshTokenExpiresAt == nil)
    }
}
