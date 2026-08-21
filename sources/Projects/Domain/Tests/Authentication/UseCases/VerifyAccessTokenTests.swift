import Testing

@testable import DomainAuthentication

// MARK: - VerifyAccessTokenTests

@Suite("VerifyAccessToken")
struct VerifyAccessTokenTests {
    @Test
    func `유효하면 오류 없이 완료하고 온보딩 상태를 변경하지 않는다`() async throws {
        let repository = VerifyAccessTokenRepository(behavior: .succeed)
        let verifyAccessToken = VerifyAccessToken(loginSessionRepository: repository)

        try await verifyAccessToken()

        #expect(await repository.onboardingChanged == false)
    }

    @Test
    func `401이면 unauthorized를 그대로 전파한다`() async throws {
        let verifyAccessToken = VerifyAccessToken(
            loginSessionRepository: VerifyAccessTokenRepository(behavior: .fail(.unauthorized))
        )

        await #expect(throws: LoginSessionError.unauthorized) {
            try await verifyAccessToken()
        }
    }

    @Test
    func `일시적 실패를 그대로 전파한다`() async throws {
        let verifyAccessToken = VerifyAccessToken(
            loginSessionRepository: VerifyAccessTokenRepository(behavior: .fail(.temporarilyUnavailable))
        )

        await #expect(throws: LoginSessionError.temporarilyUnavailable) {
            try await verifyAccessToken()
        }
    }
}

// MARK: - VerifyAccessTokenRepository

private actor VerifyAccessTokenRepository: LoginSessionRepository {

    // MARK: Lifecycle

    init(behavior: Behavior) {
        self.behavior = behavior
    }

    // MARK: Internal

    enum Behavior: Sendable {
        case succeed
        case fail(LoginSessionError)
    }

    private(set) var onboardingChanged = false

    func start(with _: AuthenticationGrant) async throws -> AuthenticatedUser {
        throw LoginSessionError.temporarilyUnavailable
    }

    func restore() async throws -> AuthenticatedUser? {
        nil
    }

    func signOut() async throws { }
    func currentSession() async -> SessionRecord? {
        nil
    }

    func replaceTokens(_: SessionTokens) async throws { }

    func updateOnboarding(_: LocalOnboardingState) async throws {
        onboardingChanged = true
    }

    func refresh() async throws -> SessionTokens {
        throw LoginSessionError.temporarilyUnavailable
    }

    func verifyAccessToken() async throws {
        switch behavior {
        case .succeed:
            return

        case .fail(let error):
            throw error
        }
    }

    // MARK: Private

    private let behavior: Behavior

}
